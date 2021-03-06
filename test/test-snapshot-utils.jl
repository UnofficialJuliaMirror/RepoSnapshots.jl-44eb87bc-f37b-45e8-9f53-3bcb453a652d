import RepoSnapshots
import Test

git = RepoSnapshots.Utils._get_git_binary_path()

previous_directory = pwd()

temp_directory_1 = joinpath(mktempdir(), "TEMPGITREPOLOCAL")
mkpath(temp_directory_1)

temp_directory_2 = joinpath(mktempdir(), "TEMPGITREPOREMOTE")
mkpath(temp_directory_2)

cd(temp_directory_2)
run(`$(git) init --bare`)

cd(temp_directory_1)
run(`$(git) init`)
RepoSnapshots.Utils.git_add_all!()
RepoSnapshots.Utils.git_commit!(
    ;
    message="test commit 1",
    allow_empty=true,
    committer_name="test name",
    committer_email="test email",
    )
run(`git branch branch1`)
run(`git branch branch2`)
run(`git branch branch3`)

run(`git checkout master`)
Test.@test( typeof(RepoSnapshots.Utils.git_version()) <: VersionNumber )
Test.@test( typeof(RepoSnapshots.Utils.get_all_branches_local()) <: Vector{String} )
Test.@test( typeof(RepoSnapshots.Utils.get_all_branches_local_and_remote()) <: Vector{String} )
Test.@test( typeof(RepoSnapshots.Utils.get_current_branch()) <: String )
Test.@test( RepoSnapshots.Utils.branch_exists("branch1") )
Test.@test( !RepoSnapshots.Utils.branch_exists("non-existent-branch") )
Test.@test( !RepoSnapshots.Utils.branch_exists("non-existent-but-create-me") )
Test.@test( typeof(RepoSnapshots.Utils.checkout_branch!("branch1")) <: Nothing )
# Test.@test_throws(
#     ErrorException,
#     RepoSnapshots.Utils.checkout_branch!("non-existent-branch"),
#     )
Test.@test_warn(
    "",
    RepoSnapshots.Utils.checkout_branch!("non-existent-branch"; error_on_failure=false,),
    )
Test.@test(
    typeof(
        RepoSnapshots.Utils.checkout_branch!("non-existent-but-create-me"; create=true)
        ) <: Nothing
    )
RepoSnapshots.Utils.git_add_all!()
RepoSnapshots.Utils.git_commit!(
    ;
    message="test commit 2",
    allow_empty=true,
    committer_name="test name",
    committer_email="test email",
    )
run(`git checkout master`)
Test.@test( RepoSnapshots.Utils.branch_exists("branch1") )
Test.@test( !RepoSnapshots.Utils.branch_exists("non-existent-branch") )
Test.@test( RepoSnapshots.Utils.branch_exists("non-existent-but-create-me") )

run(`$(git) remote add origin $(temp_directory_2)`)
Test.@test( typeof(RepoSnapshots.Utils.git_push_upstream_all!()) <: Nothing )

run(`git checkout master`)
include_patterns = Regex[
    r"^bRANCh1$"i,
    r"^bRanCh3$"i,
    ]
exclude_patterns = Regex[
    r"^brANcH3$"i,
    ]
branches_to_snapshot = RepoSnapshots.Utils.make_list_of_branches_to_snapshot(
    ;
    default_branch = "maSTeR",
    include = include_patterns,
    exclude = exclude_patterns,
    )
Test.@test( length(branches_to_snapshot) == 2 )
Test.@test( length(unique(branches_to_snapshot)) == 2 )
Test.@test(
    length(branches_to_snapshot) == length(unique(branches_to_snapshot))
    )
Test.@test( branches_to_snapshot[1] == "branch1" )
Test.@test( branches_to_snapshot[2] == "master" )

cd(previous_directory)

RepoSnapshots.Utils.delete_everything_except_dot_git!(temp_directory_1)
RepoSnapshots.Utils.delete_only_dot_git!(temp_directory_2)

rm(temp_directory_1; recursive=true, force=true)
rm(temp_directory_2; recursive=true, force=true)
