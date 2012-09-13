package Blog::Controller;
use v5.16;

use Blog::Controller::Resource;

use parent 'Web::Machine';

sub new { (shift)->SUPER::new( resource => 'Blog::Controller::Resource' ) }

1;