# CHIP 8.5: Intro to Rspec and TDD

## Introduction

In this assignment you will take a deep dive into both the concepts and mechanics of doing test-driven development 
(TDD) with the RSpec testing framework, using the Guard tool to automatically re-run tests as you change code and 
using [WebMock](https://github.com/bblimke/webmock?tab=readme-ov-file#webmock) to provide "canned" responses for 
tests that exercise code that communicates with an external service. The basic flow of TDD is red-green-refactor: 
write a test that fails (red), add code to make that test pass (green), look for opportunities to clean up your code 
and tests (refactor), repeat until all test cases are done.

The assignment is divided into the following five parts:

1. Basic setup of RSpec and Guard, and how to manually and automatically run specs
2. From red to green: getting the first spec to pass
3. From green to refactor: more controller specs and DRYing out tests
4. The model spec: stubbing the Internet with WebMock
5. Implementing `find_in_tmdb`, and stubbing the Internet

## Parts
- [Part 1 - TDD drives creating route, view, and controller method](Part-1.md)
- [Part 2 - Getting the first spec to pass](Part-2.md)
- [Part 3 - More controller behaviors](Part-3.md)
- [Part 4 - TDD for the Model](Part-4.md)
- [Part 5 - Implementing find_in_tmdb, and Stubbing the Internet](Part-5.md)
- [Submission-Instructions](Submission-Instructions.md)