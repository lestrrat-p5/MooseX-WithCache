#line 1
use strict;
use warnings;

package SVN::Repos;
use SVN::Base qw(Repos svn_repos_);

#line 145

# Build up a list of methods as we go through the file.  Add each method
# to @methods, then document it.  The full list of methods is then
# instantiated at the bottom of this file.
#
# This should make it easier to keep the documentation and list of methods
# in sync.

my @methods = (); # List of methods to wrap

push @methods, qw(fs);

#line 162

push @methods, qw(get_logs);

#line 258

push @methods,
     qw( version open create delete hotcopy recover3 recover2
         recover db_logfiles path db_env conf_dir svnserve_conf
         get_commit_editor get_commit_editor2 fs_commit_txn
         lock_dir db_lockfile db_logs_lockfile hook_dir
         pre_revprop_change_hook pre_lock_hook pre_unlock_hook
         begin_report2 begin_report link_path3 link_path2 link_path
         delete_path finish_report dir_delta2 dir_delta replay2 replay
         dated_revision stat deleted_rev history2 history
         trace_node_locations fs_begin_txn_for_commit2
         fs_begin_txn_for_commit fs_begin_txn_for_update fs_lock
         fs_unlock fs_change_rev_prop3 fs_change_rev_prop2
         fs_change_rev_prop fs_revision_prop fs_revision_proplist
         fs_change_node_prop fs_change_txn_prop node_editor
         node_from_baton dump_fs2 dump_fs load_fs2 load_fs
         authz_check_access check_revision_access invoke_authz_func
         invoke_authz_callback invoke_file_rev_handler
         invoke_history_func);

{
    no strict 'refs';
    for (@methods) {
        *{"_p_svn_repos_t::$_"} = *{$_};
    }
}

#line 304

1;
