# Title

This project is created due to show my ruby skills.
In this application I used Wireless Turbo, tailwind
And pure Ruby code, for implementing searching in JSON file

## Architecture

All logic is located in `app/models`

Two main classes are `Query` and `List`

`List` class responsible for returning filtrated origin list

`Query` class is subclass of `List`, it's responsible for
processing input query data, filtrating origin list, and returning ids of
required elements

`Query` class has few modules `QueryFinders`, `QueryHandlers`, `QueryMatchers`
They are responsible for coresponding prefix

## Development

It's pure Ruby project created by command
```rails new test_search -c tailwind```

No 3rd party services wasn't used
