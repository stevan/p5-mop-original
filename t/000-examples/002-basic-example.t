#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

class BankAccount {
    has $balance = 0;

    method balance { $balance }

    method deposit ($amount) { $balance += $amount }

    method withdraw ($amount) {
        ($amount <= $balance)
            || die "Account overdrawn";
        $balance -= $amount;
    }
}

class CheckingAccount (extends => BankAccount) {
    has $overdraft_account;

    method overdraft_account { $overdraft_account }

    method withdraw ($amount) {

        my $overdraft_amount = $amount - $self->balance;

        if ( $overdraft_account && $overdraft_amount > 0 ) {
            $overdraft_account->withdraw( $overdraft_amount );
            $self->deposit( $overdraft_amount );
        }

        super( $amount );
    }
}

ok BankAccount->instance_isa( $::Object ), '... BankAccount is a subclass of Object';

ok CheckingAccount->instance_isa( BankAccount ), '... CheckingAccount is a subclass of BankAccount';
ok CheckingAccount->instance_isa( $::Object ), '... CheckingAccount is a subclass of Object';

my $savings = BankAccount->new( balance => 250 );
is mop::class_of( $savings ), BankAccount, '... got the class we expected';
ok $savings->isa( BankAccount ), '... savings is an instance of BankAccount';

is $savings->balance, 250, '... got the savings balance we expected';

$savings->withdraw( 50 );
is $savings->balance, 200, '... got the savings balance we expected';

$savings->deposit( 150 );
is $savings->balance, 350, '... got the savings balance we expected';

like(exception {
    $savings->withdraw( 400 );
}, qr/Account overdrawn/, '... got the expection we expected');

my $checking = CheckingAccount->new(
    overdraft_account => $savings,
);
is mop::class_of( $checking ), CheckingAccount, '... got the class we expected';
ok $checking->isa( CheckingAccount ), '... checking is an instance of BankAccount';
ok $checking->isa( BankAccount ), '... checking is an instance of BankAccount';

is $checking->balance, 0, '... got the checking balance we expected';

$checking->deposit( 100 );
is $checking->balance, 100, '... got the checking balance we expected';
is $checking->overdraft_account, $savings, '... got the right overdraft account';

$checking->withdraw( 50 );
is $checking->balance, 50, '... got the checking balance we expected';
is $savings->balance, 350, '... got the savings balance we expected';

$checking->withdraw( 200 );
is $checking->balance, 0, '... got the checking balance we expected';
is $savings->balance, 200, '... got the savings balance we expected';

done_testing;



