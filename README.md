# Comment Card

*Comment card provides a simplified interface for both authenticated and anonymous non-technical users to provide feedback for your GitHub-hosted project*

**[Live Demo](#)**

## Setup

Comment card is designed to run on Heroku, but can run in any Ruby environment.

1. [Register a new OAuth application](https://github.com/settings/applications/new)
2. Set `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` as environmental variables

That's it. Simply swap out `github.com` with your Comment Card instance for any link to the new issue URL.

For example, if your project's new comment url is `https://github.com/benbalter/comment-card/issues/new` and your Comment Card instance is as `comment-card.herokuapp.com`, you'd link users to `https://comment-card.herokuapp.com/benbalter/comment-card/issues/new` to submit comments.

## Allowing pseudonymous submissions

You can also configure Comment Card to allow pseudonymous submissions that don't require submitters to have a GitHub login:

1. Create a "bot" account (a dummy GitHub user that can be used to create the issues)
2. Login as that user and [create a personal access token](https://github.com/settings/tokens/new) with `public_repo` scope
3. Set the token as the `GITHUB_TOKEN` environmental variable

Users then will have the choice to enter their name or authenticate with GitHub before submitting. Note: If publicly accessible, this may allow for spam or abusive comments.
