package mopx::instance::tracking::role;
use strict;
use warnings;

use mop;
use Set::Object::Weak 'weak_set';

role InstanceTrackingRole {
    has $instances = weak_set();

    method instances { return $instances->members }

    # ->subclasses doesn't work yet
    # method get_all_instances { return map { $_->instances } $self, $self->subclasses }

    method _track_instance ($instance) {
        $instances->insert($instance);
    }

    method _untrack_instance ($instance) {
        $instances->remove($instance);
    }

    method create_instance ($params) {
        my $instance = super($params);
        $self->_track_instance($instance);
        return $instance;
    }
}

sub import {
    my $caller = caller;
    mop->import(-metaroles => [ InstanceTrackingRole ]);
}

1;

