#!perl

use v5.14;

package TaskTracker {
    use mop;

    package TaskTracker::Model {
        use mop;
        use JSON::PP ();

        my $JSON = JSON::PP->new->pretty->canonical;

        role Packable { method pack }

        role Serializable (roles => [Packable]) {
            method serialize { $JSON->encode( $self->pack ) }
        }

        class TaskList (roles => [Serializable]) {
            has $tasks = [];

            method add_task ( $task ) { push @$tasks => $task }

            method pack {
                return +{
                    'tasks' => [
                        map  { $_->pack }
                        sort { $b->priority <=> $a->priority }
                             @$tasks
                    ]
                }
            }
        }

        class Task (roles => [Serializable]) {
            has $priority = 0.0;
            has $desc     = '...';
            has $subtasks;

            BUILD {
                warn $subtasks;
            }

            method priority ( $p ) { $priority = $p if $p; $priority }
            method desc     ( $d ) { $desc     = $d if $d; $desc     }

            method pack {
                return +{
                    'desc'     => $desc,
                    'priority' => $priority,
                    'subtasks' => $subtasks->pack
                }
            }
        }

    }

}

my $list = TaskTracker::Model::TaskList->new(
    tasks => [
        TaskTracker::Model::Task->new(
            desc     => 'Create TaskTracker app',
            priority => 1.0
        ),
        TaskTracker::Model::Task->new(
            desc     => 'Test TaskTracker app',
            priority => 0.5
        ),
        TaskTracker::Model::Task->new(
            desc     => 'Fly to JFK',
            priority => 0.75,
            subtasks => TaskTracker::Model::TaskList->new(
                tasks => [
                    TaskTracker::Model::Task->new(
                        desc     => 'Board Plane',
                        priority => 1.0
                    ),
                    TaskTracker::Model::Task->new(
                        desc     => 'Sleep on plane',
                        priority => 0.5
                    ),
                ]
            )
        ),
    ]
);

say $list->serialize;


1;

