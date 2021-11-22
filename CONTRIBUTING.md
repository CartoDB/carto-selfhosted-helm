# Contributing to this repository

Thanks for taking the time to contribute! The following is a set of guidelines for contributing to our project.
We encourage everyone to follow them with their best judgement.

## Table of Contents

* [How to Prepare a PR](#how-to-prepare-a-pr)
    * [The Essentials of a Code Contribution](#the-essentials-of-a-code-contribution)
    * [Creating a Pull Request](#creating-the-pull-request)
* [Branching Strategy](#branching-strategy)
* [Merging a Pull Request](#merging-a-pull-request)

## How to Prepare a PR

Pull requests let you tell others about changes you have pushed to a branch in our repository. They are a dedicated forum for discussing the implementation of the proposed feature or bugfix between committer and reviewer(s).

This is an essential mechanism to maintain or improve the quality of our codebase, so let's see what we look for in a pull request.

The following are all formal requirements to be met before considering the content of the proposed changes.

### The Essentials of a Code Contribution

Here we cover the configuration of the tools that will help you write code that complies with our standards and also the good practices that will make your contribution as useful as it can be!

#### Git Client Configuration

First things first, Git is the base from which everything is built upon, so we want to make it as solid as possible.

- Start off by configuring your `user.name` and `user.email` as seen in [Customizing Git](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration). The `user.email` parameter should always be the VMware corporate one. For your convenience, here is a good resource on [Maintaining Different Git Identities](https://xam.io/2017/gitconfig/).
- Next, we want to be able to verify that commits are actually from a trusted source, so we are going to sign and verify our work with GPG.
    - Github has a neat set of guides that will help you [check for existing GPG keys](https://docs.github.com/en/articles/checking-for-existing-gpg-keys), [generate a new GPG key](https://docs.github.com/en/articles/generating-a-new-gpg-key) in case you don't already have one, [tell Git about your signing key](https://docs.github.com/en/articles/telling-git-about-your-signing-key) and of course show you how to [sign commits](https://docs.github.com/en/articles/signing-commits).
- Finally, we want to publish our work and *only* our work. There is one thing that might bother us and the people we work with: line endings.
    - Fortunately, Github has us covered again, check [Configuring Git to handle line endings](https://docs.github.com/en/github/using-git/configuring-git-to-handle-line-endings) for Mac, Windows and Linux.

#### Making your Changes Clear and Traceable

There's a **Golden Rule** when adressing code changes: **Modify only what is related to the task**.

When developing the next feature or bugfix we should also strive for small, atomic commits or, in other words, commits that group changes focused on one context and one context only.
They are easier to read, understand, review, track and revert.

You can use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit message structure. A well-crafted Git commit message is the best way to communicate context about a change. Here is a good resource on [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/) or just skip to the [guidelines](https://chris.beams.io/posts/git-commit/#seven-rules).

Also, note that the commits will be squashed when merging the pull request, by doing a fast-forward merge. Regarding the squash commit message:

* If the PR contains a single commit, there won't be any squash and the commit will go directly to the target branch.
* If there are multiple commits, the message will default to the pull request title.

A final caveat to be aware of is that the fast-forward strategy requires that your branch is up-to-date with the target branch, so you will have to rebase / merge the target branch into your branch before merging the pull request.

### Creating a Pull Request

There are three important parts in a pull request:
- **Title**. Use a well descriptive but not too long message about what this change is about.
- **Description**. Do your best to put only relevant information. It is perfectly valid to leave it empty! But please, don't leave all your commit messages there.
- **Destination branch**. The destination branch is determined by the [Branching Strategy](#branching-strategy) section you can find below.

Additionally, there are other fields that can be useful:

- **Asignee**. Set one or multiple assignees.

Finally, when the work is still in progress remember to set the PR as draft like explaine in the [GitHub documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/changing-the-stage-of-a-pull-request).

## Branching Strategy

[Git](https://git-scm.com/) is our version control system for tracking changes in our codebase. As you may know, in Git's implementation, branching is really cheap!
So we need an orderly, controlled way of dealing with them: Enter Branching Strategy. This is the set of rules in which we base our workflow.

### Key branches

**stable**.
- Protected branch
- Prevent changes without a pull request
- Changes come from a `feature` or `bugfix` branch
- Merge strategy is **always** `--squash`
- Releases are triggered manually from this branch

### Supporting branches

**feature branches**
- One branch per *feature*
- May branch off from `stable`
- Naming convention is `feature/FEAT-NAME`

**bugfix branches**
- One branch per *bugfix*
- May branch off from `stable`
- Naming convention is `bugfix/BUGFIX-NAME`

**revert branches**
- One branch per *revert*
- May branch off from `stable`
- Naming convention is `revert/REVERT-NAME`

## Merging a Pull Request

Here there's one **Golden Rule**:
- **Who pushes the changes, merges the changes**. The author of the changes is the one who knows if the acceptance criteria of the related issue are completely met.

There is also a set of requirements to fulfill before merging a pull request:
- **Wait for the PR-verify to be successful**. PR-verify lets everyone know if your commits meet the conditions set for our repository.
- **The acceptance criteria of the related issue are completely met**.
- **All comments by reviewers have been addressed**.
- **It is approved by whoever reviewed it**.
- **Sync before merge**. So you verify that everything works as expected with the latest revision of the destination branch.