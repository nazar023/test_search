# Title

This project is created due to show my ruby skills.
In this application I used Wireless Turbo, tailwind
And pure Ruby code, for implementing searching in JSON file

## Architecture

All logic is located in `home_search_helper`
It has one public method ``search_elements_from_list`` which filtrates list
In this project weren't used any sort of DB

## Development

It's pure Ruby project created by command
```rails new test_search -c tailwind```

No 3rd party services wasn't used

## Steps of searching

First step is to normalize query, I downcase it and split via ' '
After we are finding id's of elements with negative prompts

Then we can start filrating our list
Each word is being filtrated by 4 types (Author, Language, Type or something else)
If any connection between query and any type was found, we filtrate it accordingly to type

After finding all necessary elements app substracts negative_prompts id's from
filtrated list, leaving only needed to user elements and return it.
