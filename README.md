# Title

This project is created to show my ruby skills.
In this application, I used Wireless Turbo, tailwind
And pure Ruby code, for implementing searching in JSON file

## How to start?

  To try this project clone this repository
  ```git clone git@github.com:nazar023/test_search.git YOUR_DIRECTORY_PATH```

  And start it
  ```bin/dev```

## Architecture

All logic is located in `app/models`

Two main classes are `Query` and `List`

`List` class responsible for returning filtrated origin list

`Query` class is a subclass of `List`, it's responsible for
processing input query data, filtrating origin list, and returning IDs of
required elements

`Query` class has a few modules `QueryFinders`, `QueryHandlers`, `QueryMatchers`
They are responsible for the corresponding prefix

## Development

It's a pure Ruby project created by the command
```rails new test_search -c tailwind```

No 3rd party services were used

