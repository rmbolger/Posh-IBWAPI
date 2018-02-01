# How to Help

## Submit Issues

First and foremost, submit new [Issues](https://github.com/rmbolger/Posh-IBWAPI/issues) if you run into bugs or weirdness when you're using the module. Especially now that the module works cross platform with PowerShell Core, there will undoubtedly be platform specific bugs that I won't catch because my primary platform is Windows. I don't even have a Mac to test against. Even if it's just that you can't figure out how to do something using the WAPI, I'm happy to help figure it out.

## Write Tests

This project is my first attempt at writing [Pester](https://github.com/pester/Pester) tests for PowerShell (and unit testing in general). Help me get better by adding tests to the project. I'm also open to code refactoring suggestions that will make testing easier. Most of the code written so far definitely wasn't done with testing in mind.

## Add to the Wiki

Is there some documentation you wish you had when you were first playing with the module? Are you running on an ancient NIOS version that I don't have mapped in my [WAPI to NIOS version mapping](https://github.com/rmbolger/Posh-IBWAPI/wiki/Unofficial-WAPI-to-NIOS-version-mapping) table? Did I make a spelling mistake? Does my grammar suck?

## Features and Functionality

If you have an idea for a new feature or functionality change, submit an issue first so we can discuss it. I'd hate for you to waste time implementing a feature that I may never pull into the project.

## Code Guidelines

I'm trying to keep this a pure PowerShell script module without any non-native dependencies. Keep in mind that this module supports both classic Windows PowerShell and the cross-platform PowerShell Core. So please try to avoid platform specific calls.

I'm not super strict about code formatting as long as it seems readable. I'm a bit OCD about removing white space at the end of lines in my own commits though. Just don't make huge commits that contain a bunch of whitespace or formatting changes.

## Say Hi and Tell Your Friends

There's nothing that makes me want to work on this project more than knowing people use it other than myself. Drop me a line on Twitter ([@rmbolger](https://twitter.com/rmbolger)). Tell your friends that use Infoblox about it. I'm a huge introvert and terrible at self-promotion.
