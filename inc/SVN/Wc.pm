#line 1
use strict;
use warnings;

package SVN::Wc;
use SVN::Base qw(Wc svn_wc_);
use SVN::Core;

#line 18

swig_init_asp_dot_net_hack($SVN::Core::gpool);

package _p_svn_wc_t;

#line 72

package _p_svn_wc_status_t;
use SVN::Base qw(Wc svn_wc_status_t_);

#line 179

package _p_svn_wc_entry_t;
# still need to check if the function prototype allows it to be called
# as method.
use SVN::Base qw(Wc svn_wc_entry_t_);

#line 278

# no reasonable prefix for these enums
# so we have to do them one by one to import.
package SVN::Wc::Notify::Action;
our $add = $SVN::Wc::notify_add;
our $copy = $SVN::Wc::notify_copy;
our $delete = $SVN::Wc::notify_delete;
our $restore = $SVN::Wc::notify_restore;
our $revert = $SVN::Wc::notify_revert;
our $failed_revert = $SVN::Wc::notify_failed_revert;
our $resolved = $SVN::Wc::notify_resolved;
our $skip = $SVN::Wc::notify_skip;
our $update_delete = $SVN::Wc::notify_update_delete;
our $update_add = $SVN::Wc::notify_update_add;
our $update_update = $SVN::Wc::notify_update_update;
our $update_completed = $SVN::Wc::notify_update_completed;
our $update_external = $SVN::Wc::notify_update_external;
our $status_completed = $SVN::Wc::notify_status_completed;
our $status_external = $SVN::Wc::notify_status_external;
our $commit_modified = $SVN::Wc::notify_commit_modified;
our $commit_added = $SVN::Wc::notify_commit_added;
our $commit_deleted = $SVN::Wc::notify_commit_deleted;
our $commit_replaced = $SVN::Wc::notify_commit_replaced;
our $commit_postfix_txdelta = $SVN::Wc::notify_commit_postfix_txdelta;
our $blame_revision = $SVN::Wc::notify_blame_revision;

#line 339

package SVN::Wc::Notify::State;
use SVN::Base qw(Wc svn_wc_notify_state_);

#line 366

package SVN::Wc::Schedule;
use SVN::Base qw(Wc svn_wc_schedule_);

#line 433

package SVN::Wc::Status;
use SVN::Base qw(Wc svn_wc_status_);

1;
