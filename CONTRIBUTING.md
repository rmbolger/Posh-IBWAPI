# IMPORTANT

If you're unsure or afraid of *anything*, just ask or submit the issue or pull request anyways. No one is going to yell or condescend for giving your best effort. Everyone was new at some point and we're all just working together to make something cool. This project is a few years old now and it was one of my first real open source projects. But I still feel like a complete novice maintaining it and I'm constantly learning new things. So no worries!

# How to Help

## Submit Issues

I'm the first to admit that I don't test nearly as much as I should. If you run into bugs, weirdness, or something just doesn't make sense, submit a new [Issue](https://github.com/rmbolger/Posh-IBWAPI/issues). Even if you just need some help using the module, a generic issue is fine.

## Unit Tests

The tests in this project now use [Pester v5](https://pester.dev/docs/quick-start). My overall code coverage is still pretty low. So if you're handy at writing tests or have suggestions to improve the existing ones, suggestions and pull requests are most welcome. The recommended way to run the tests is in a separate PowerShell process due to some limitations in how Pester is able to test internal module stuff. For example:

```powershell
cd \path\to\Posh-IBWAPI

# Windows PowerShell
powershell.exe -C "Invoke-Pester"

# PowerShell 6+
pwsh.exe -C "Invoke-Pester"
```

Keep in mind, the tests should be able to pass on Windows with PowerShell as old as 3.0 with .NET 4.5. They should also pass with PowerShell 6+ on any OS.

## The Wiki

Is there some documentation you wish you had when you were first playing with the module? Are you running on an ancient NIOS version that I don't have mapped in my [WAPI to NIOS version mapping](https://github.com/rmbolger/Posh-IBWAPI/wiki/Unofficial-WAPI-to-NIOS-version-mapping) table? Did I make a spelling mistake? Is my grammar poor? Did you write a blog post or article somewhere about using the module. Submit an issue and tell me about any of these things.

## Features and Functionality

I know there are loads of use cases I haven't considered. If you have an idea for a new feature or functionality change, submit an issue first so we can discuss it. I'd hate for you to waste time implementing a feature that I may never pull into the project.

## Code Guidelines

I'm trying to keep this a pure PowerShell script module without any non-native dependencies. Keep in mind that this module supports both classic Windows PowerShell and the cross-platform PowerShell Core. So please try to avoid platform specific calls.

I'm not super strict about code formatting as long as it seems readable. I'm a bit OCD about removing white space at the end of lines in my own commits though. Just don't make huge commits that contain a bunch of whitespace or formatting changes.

## Say Hi and Tell Your Friends

There's nothing that makes me want to work on this project more than knowing people use it other than myself. Drop me a line on Twitter ([@rmbolger](https://twitter.com/rmbolger)) and tell your friends about it.
