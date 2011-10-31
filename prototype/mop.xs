#include "EXTERN.h"
#include "perl.h"
#include "callparser0.h"
#include "XSUB.h"

/* stolen from Scope::Escape::Sugar */

#define SVt_PADNAME SVt_PVMG

#ifndef COP_SEQ_RANGE_LOW_set
# define COP_SEQ_RANGE_LOW_set(sv,val) \
	do { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = val; } while(0)
# define COP_SEQ_RANGE_HIGH_set(sv,val) \
	do { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = val; } while(0)
#endif /* !COP_SEQ_RANGE_LOW_set */

/*
 * pad handling
 *
 * The public API for the pad system is lacking any way to add items to
 * the pad.  This is a minimal implementation of the necessary facilities.
 * It doesn't warn about shadowing.
 */

#define pad_add_my_scalar_pvn(namepv, namelen) \
		THX_pad_add_my_scalar_pvn(aTHX_ namepv, namelen)
static PADOFFSET THX_pad_add_my_scalar_pvn(pTHX_
	char const *namepv, STRLEN namelen)
{
	PADOFFSET offset;
	SV *namesv, *myvar;
	myvar = *av_fetch(PL_comppad, AvFILLp(PL_comppad) + 1, 1);
	offset = AvFILLp(PL_comppad);
	SvPADMY_on(myvar);
	PL_curpad = AvARRAY(PL_comppad);
	namesv = newSV_type(SVt_PADNAME);
	sv_setpvn(namesv, namepv, namelen);
	COP_SEQ_RANGE_LOW_set(namesv, PL_cop_seqmax);
	COP_SEQ_RANGE_HIGH_set(namesv, PERL_PADSEQ_INTRO);
	PL_cop_seqmax++;
	av_store(PL_comppad_name, offset, namesv);
	return offset;
}

#define pad_add_my_scalar_sv(namesv) THX_pad_add_my_scalar_sv(aTHX_ namesv)
static PADOFFSET THX_pad_add_my_scalar_sv(pTHX_ SV *namesv)
{
	char const *pv;
	STRLEN len;
	pv = SvPV(namesv, len);
	return pad_add_my_scalar_pvn(pv, len);
}

/*
 * parser pieces
 *
 * These functions reimplement fairly low-level parts of the Perl syntax,
 * using the character-level public lexer API.
 */

#define DEMAND_IMMEDIATE 0x00000001
#define DEMAND_NOCONSUME 0x00000002
#define demand_unichar(c, f) THX_demand_unichar(aTHX_ c, f)
static void THX_demand_unichar(pTHX_ I32 c, U32 flags)
{
	if(!(flags & DEMAND_IMMEDIATE)) lex_read_space(0);
	if(lex_peek_unichar(0) != c) croak("syntax error");
	if(!(flags & DEMAND_NOCONSUME)) lex_read_unichar(0);
}

#define parse_idword(prefix) THX_parse_idword(aTHX_ prefix)
static SV *THX_parse_idword(pTHX_ char const *prefix)
{
	STRLEN prefixlen, idlen;
	SV *sv;
	char *start, *s, c;
	s = start = PL_parser->bufptr;
	c = *s;
	if(!isIDFIRST(c)) croak("syntax error");
	do {
		c = *++s;
	} while(isALNUM(c));
	lex_read_to(s);
	prefixlen = strlen(prefix);
	idlen = s-start;
	sv = sv_2mortal(newSV(prefixlen + idlen));
	Copy(prefix, SvPVX(sv), prefixlen, char);
	Copy(start, SvPVX(sv)+prefixlen, idlen, char);
	SvPVX(sv)[prefixlen + idlen] = 0;
	SvCUR_set(sv, prefixlen + idlen);
	SvPOK_on(sv);
	return sv;
}

#define parse_scalar_varname() THX_parse_scalar_varname(aTHX)
static SV *THX_parse_scalar_varname(pTHX)
{
	demand_unichar('$', DEMAND_IMMEDIATE);
	lex_read_space(0);
	return parse_idword("$");
}

/* end stolen from Scope::Escape::Sugar */

#define caller_package() THX_caller_package(aTHX)
static SV *THX_caller_package(pTHX)
{
    return sv_2mortal(newSVpv(HvNAME(PL_curstash), 0));
}

#define parse_metadata() THX_parse_metadata(aTHX)
static OP *THX_parse_metadata(pTHX)
{
    OP *metadata;

    demand_unichar('(', DEMAND_IMMEDIATE);
    metadata = parse_listexpr(0);
    lex_read_space(0);
    demand_unichar(')', 0);

    return metadata;
}

static OP *parse_class(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    SV *caller, *class_name, *metadata, *class;
    CV *metadata_cv;
    OP *metadata_op, *local_class, *self_class_lexicals, *block;
    int floor;

    *flagsp |= CALLPARSER_STATEMENT;

    /* get caller */
    caller = caller_package();

    /* parse class name */
    lex_read_space(0);
    class_name = parse_idword("");

    /* parse metadata */
    floor = start_subparse(0, 0);
    lex_read_space(0);
    if (lex_peek_unichar(0) == '(') {
        metadata_op = newANONHASH(parse_metadata());
    }
    else {
        metadata_op = newOP(OP_UNDEF, 0);
    }

    /* evaluate metadata at compile time */
    ENTER;
    {
        dSP;
        CV *metadata_cv;
        metadata_cv = newATTRSUB(floor, NULL, NULL, NULL, metadata_op);
        PUSHMARK(SP);
        call_sv((SV*)metadata_cv, G_SCALAR|G_NOARGS);
        SPAGAIN;
        metadata = POPs;
        PUTBACK;
    }
    LEAVE;

    /* call mop::syntax::build_class with the name and metadata */
    ENTER;
    {
        dSP;
        PUSHMARK(SP);
        EXTEND(SP, 3);
        PUSHs(class_name);
        PUSHs(metadata);
        PUSHs(caller);
        PUTBACK;
        call_pv("mop::syntax::build_class", G_SCALAR);
        SPAGAIN;
        class = POPs;
        PUTBACK;
    }
    LEAVE;

    /* localize $::CLASS to the class that we built */
    floor = start_subparse(0, 0);
    local_class = newASSIGNOP(0, op_lvalue(newUNOP(OP_RV2SV, 0, newGVOP(OP_GV, 0, gv_fetchpv("::CLASS", 0, SVt_PV))), OP_NULL), 0, newSVOP(OP_CONST, 0, newSVsv(class)));

    /* create $self and $class lexicals */
    {
        OP *var_self, *var_class;

        var_self = newOP(OP_PADSV, 0);
        var_self->op_targ = pad_add_my_scalar_pvn("$self", 5);
        var_class = newOP(OP_PADSV, 0);
        var_class->op_targ = pad_add_my_scalar_pvn("$class", 6);
        self_class_lexicals = newLISTOP(OP_LIST, 0, var_self, var_class);
    }

    /* parse the class block */
    demand_unichar('{', DEMAND_NOCONSUME);
    block = parse_block(0);

    /* stick localization and the lexicals on the front of the block */
    block = op_prepend_elem(OP_LINESEQ,
                            newSTATEOP(0, NULL, self_class_lexicals),
                            block);
    block = op_prepend_elem(OP_LINESEQ,
                            newSTATEOP(0, NULL, local_class),
                            block);

    /* evaluate the class block at compile time */
    ENTER;
    {
        dSP;
        CV *class_cv;
        class_cv = newATTRSUB(floor, NULL, NULL, NULL, block);
        PUSHMARK(SP);
        call_sv((SV*)class_cv, G_VOID|G_NOARGS);
        PUTBACK;
    }
    LEAVE;

    /* finalize the class, still at compile time */
    ENTER;
    {
        dSP;
        PUSHMARK(SP);
        EXTEND(SP, 3);
        PUSHs(class_name);
        PUSHs(class);
        PUSHs(caller);
        PUTBACK;
        call_pv("mop::syntax::finalize_class", G_VOID);
        PUTBACK;
    }
    LEAVE;

    /* the class keyword has no runtime component */
    return newOP(OP_NULL, 0);
}

static OP *parse_has(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    SV *varname;
    OP *ret, *pad_op, *metadata = NULL, *attr_default = NULL;

    *flagsp |= CALLPARSER_STATEMENT;

    lex_read_space(0);
    varname = parse_scalar_varname();

    lex_read_space(0);
    if (lex_peek_unichar(0) == '(') {
        metadata = newANONHASH(parse_metadata());
    }

    lex_read_space(0);
    if (lex_peek_unichar(0) != ';') {
        I32 floor;

        demand_unichar('=', 0);
        lex_read_space(0);
        floor = start_subparse(0, 0);
        attr_default = newANONSUB(floor, NULL, parse_termexpr(0));
    }

    pad_op = newOP(OP_PADSV, (OPpLVAL_INTRO<<8)|OPf_PARENS|OPf_WANT_LIST);
    pad_op->op_targ = pad_add_my_scalar_sv(varname);

    SvREFCNT_inc(varname);
    ret = newLISTOP(OP_LIST, 0,
                    newSVOP(OP_CONST, 0, varname),
                    newUNOP(OP_REFGEN, 0, pad_op));

    if (metadata) {
        op_append_elem(OP_LIST, ret, metadata);
    }
    else {
        op_append_elem(OP_LIST, ret, newOP(OP_UNDEF, 0));
    }

    if (attr_default) {
        op_append_elem(OP_LIST, ret, attr_default);
    }

    return ret;
}

#define parse_method_prototype() THX_parse_method_prototype(aTHX)
static OP *THX_parse_method_prototype(pTHX)
{
    OP *myvars, *get_args;

    demand_unichar('(', DEMAND_IMMEDIATE);

    lex_read_space(0);
    if (lex_peek_unichar(0) == ')') {
        lex_read_unichar(0);
        return NULL;
    }

    myvars = newLISTOP(OP_LIST, 0, NULL, NULL);

    for (;;) {
        SV *varname;
        OP *pad_op;
        char next;

        lex_read_space(0);
        varname = parse_scalar_varname();

        pad_op = newOP(OP_PADSV, (OPpLVAL_INTRO<<8));
        pad_op->op_targ = pad_add_my_scalar_sv(varname);
        op_append_elem(OP_LIST, myvars, pad_op);

        lex_read_space(0);
        next = lex_peek_unichar(0);
        if (next == ',') {
            lex_read_unichar(0);
        }
        else if (next == ')') {
            lex_read_unichar(0);
            break;
        }
        else {
            croak("syntax error");
        }
    }

    get_args = newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, gv_fetchpv("_", 0, SVt_PVAV)));

    return newASSIGNOP(0, myvars, 0, get_args);
}

static OP *parse_method(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    I32 floor;
    SV *method_name = NULL;
    OP *arg_assign = NULL, *block, *code;

    *flagsp |= CALLPARSER_STATEMENT;

    floor = start_subparse(0, 0);

    if (SvTRUE(psobj)) {
        lex_read_space(0);
        method_name = parse_idword("");
    }

    lex_read_space(0);
    if (lex_peek_unichar(0) == '(') {
        arg_assign = parse_method_prototype();
    }

    demand_unichar('{', DEMAND_NOCONSUME);

    block = parse_block(0);

    if (arg_assign) {
        block = op_prepend_elem(OP_LINESEQ,
	                        newSTATEOP(0, NULL, arg_assign),
	                        block);
    }

    code = newANONSUB(floor, NULL, block);

    if (SvTRUE(psobj)) {
        SvREFCNT_inc(method_name);
        return newLISTOP(OP_LIST, 0,
                         newSVOP(OP_CONST, 0, method_name),
                         code);
    }
    else {
        return code;
    }
}

MODULE = mop  PACKAGE = mop

PROTOTYPES: DISABLE

BOOT:
{
    cv_set_call_parser(get_cv("mop::syntax::class", 0), parse_class, &PL_sv_undef);
    cv_set_call_parser(get_cv("mop::syntax::has", 0), parse_has, &PL_sv_undef);
    cv_set_call_parser(get_cv("mop::syntax::method", 0), parse_method, &PL_sv_yes);
    cv_set_call_parser(get_cv("mop::syntax::BUILD", 0), parse_method, &PL_sv_no);
    cv_set_call_parser(get_cv("mop::syntax::DEMOLISH", 0), parse_method, &PL_sv_no);
}
