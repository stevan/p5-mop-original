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

#define parse_metadata() THX_parse_metadata(aTHX)
static OP *THX_parse_metadata(pTHX)
{
    OP *metadata;

    demand_unichar('(', DEMAND_IMMEDIATE);
    metadata = parse_listexpr(0);
    lex_read_space(0);
    demand_unichar(')', 0);
    lex_read_space(0);

    return metadata;
}

static OP *parse_has(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    SV *varname;
    OP *ret, *pad_op, *metadata = NULL, *attr_default = NULL;

    lex_read_space(0);
    varname = parse_scalar_varname();
    lex_read_space(0);

    if (lex_peek_unichar(0) == '(') {
        metadata = newANONHASH(parse_metadata());
    }

    if (lex_peek_unichar(0) != ';') {
        I32 floor;

        demand_unichar('=', 0);
        lex_read_space(0);
        floor = start_subparse(0, 0);
        attr_default = newANONSUB(floor, NULL, parse_termexpr(0));
    }

    *flagsp |= CALLPARSER_STATEMENT;

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

static OP *parse_block_method(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    I32 floor;
    OP *arg_assign = NULL, *block;

    *flagsp |= CALLPARSER_STATEMENT;

    floor = start_subparse(0, 0);

    lex_read_space(0);

    if (lex_peek_unichar(0) == '(') {
        arg_assign = parse_method_prototype();
    }

    lex_read_space(0);

    demand_unichar('{', DEMAND_IMMEDIATE | DEMAND_NOCONSUME);

    block = parse_block(0);

    if (arg_assign) {
        block = op_prepend_elem(OP_LINESEQ,
	                        newSTATEOP(0, NULL, arg_assign),
	                        block);
    }

    return newANONSUB(floor, NULL, block);
}

MODULE = mop  PACKAGE = mop

PROTOTYPES: DISABLE

BOOT:
{
    cv_set_call_parser(get_cv("mop::syntax::has", 0), parse_has, &PL_sv_undef);
    cv_set_call_parser(get_cv("mop::syntax::BUILD", 0), parse_block_method, &PL_sv_undef);
    cv_set_call_parser(get_cv("mop::syntax::DEMOLISH", 0), parse_block_method, &PL_sv_undef);
}
