### Alfred Workflow Modifications

The following is a list of modifications made to third-party Alfred workflows. If you ever download a new release of these, you'll need to remake these modifications

#### Google Chrome History

- Change `_MAX_RESULTS_DEFAULT` in `alfred.py` to be higher (like `50`)

#### `NEXT_MACHINE`

- Change profile paths for both history and bookmarks to be `Default` instead of `Profile 1`

#### Trello

- Changed scripts to pass in the Trello token and key via zsh env variables. If we switch to Dropbox, we can revert this change. Example:

```shell
source ~/dotfiles/.zshrc__private

key=$__TRELLO_API_KEY
token=$__TRELLO_TOKEN
boardid='5fda6dff5832a33ec469b3d8'

php -f trello.php -- "${key};${token};${boardid};{query}"
```

- Added script to capitalize the first letter of the `query`/card name