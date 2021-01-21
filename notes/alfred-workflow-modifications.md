### Alfred Workflow Modifications

The following is a list of modifications made to third-party Alfred workflows. If you ever download a new release of these, you'll need to remake these modifications

#### Recent History

- Change `_MAX_RESULTS_DEFAULT` in `alfred.py` to be higher (like `50`)
- Change the `Script Filters` behavior so that the argument is optional. This way, can more easily see recently visited sites

#### Trello

- Added Trello token and key to main script, as the [README](https://github.com/MikoMagni/Trello-Workflow-for-Alfred) suggests
- Added script to capitalize the first letter of the `query`/card name
