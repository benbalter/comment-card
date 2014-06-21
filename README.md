# Comment Card

*Comment card provides a simplified interface for both authenticated and anonymous non-technical users to provide feedback for your GitHub-hosted project*

**[Live Demo](https://comment-card.herokuapp.com/benbalter/comment-card/issues/new)**

![comment card](https://cloud.githubusercontent.com/assets/282759/3349920/a7283a1c-f982-11e3-8a92-5fa7c291bf44.png)

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

![guest login](https://cloud.githubusercontent.com/assets/282759/3349921/a8bc334c-f982-11e3-9b1b-7e691a2216b6.png)

Users then will have the choice to enter their name or authenticate with GitHub before submitting. Note: If publicly accessible, this may allow for spam or abusive comments.

## Roadmap

Take a look at the [1.0 Milestone](https://github.com/benbalter/comment-card/issues?milestone=2&state=open)

## Running locally

1. `script/bootstrap`
2. `script/server`
