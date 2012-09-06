#!/usr/bin/perl

use v5.14;
use strict;
use warnings;

use Test::More;

use mop;

my @lexical;
my @global;

class Tree {
    has $node;
    has $parent;
    has $children = [];

    method node   { $node   }
    method parent { $parent }
    method _set_parent ($p) { $parent = $p }

    method children { $children }

    method add_child ( $t ) {
        $t->_set_parent( $self );
        push @$children => $t;
        $self;
    }

    # $::CLASS->add_method($::Method->new(
    #     name => 'traverse',
    #     body => sub {
    #         my $indent = shift;
    #         $indent ||= '';
    #         # say $indent, $::SELF->node, ' => ', $self, ' => ', $::SELF;
    #         push @lexical, $self;
    #         push @global, $::SELF;
    #         foreach my $t ( @{ $::SELF->children } ) {
    #             # warn $t, ' => ', $t->node;
    #             $t->traverse( $indent . '  ' );
    #         }
    #     }
    # ));

    method traverse ($indent) {
       $indent ||= '';
       # say $indent, $node, ' => ', $self, ' => ', $::SELF;
       push @lexical, $self;
       push @global, $::SELF;
       foreach my $t ( @$children ) {
           # warn $t, ' => ', $t->node;
           $t->traverse( $indent . '  ' );
       }
    }
}


my $t = Tree->new( node => '0.0' )
            ->add_child( Tree->new( node => '1.0' ) )
            ->add_child(
                Tree->new( node => '2.0' )
                    ->add_child( Tree->new( node => '2.1' ) )
            )
            ->add_child( Tree->new( node => '3.0' ) )
            ->add_child( Tree->new( node => '4.0' ) );

#use Data::Dumper; warn Dumper $t;

local $TODO = "something in our pad munging is broken";
$t->traverse;
is_deeply(\@lexical, \@global);

done_testing;
