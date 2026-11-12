# Part 1 - TDD drives creating route, view, and controller method

## Writing a new View

As a first step we will augment RottenPotatoes with a form allowing the user to search The Movie Database (TMDb) for a
movie to add to RottenPotatoes. 

Recall that in the MVC architecture, the controller is the "first point of entry" to the app when the client makes a 
request, so we will have to pick a name for the controller action that would eventually handle this form submission; 
we will call the controller action `search_tmdb`. The first thing we'll do is create the view corresponding to that 
controller action. This view will eventually get displayed when a user navigates to `/search`. We have included a 
starter file in `search_tmdb.html.erb` but it's currently missing two things. First the form parameters that it should 
be submitted with, and second a button that takes us back to the home page. 

Include the route path and method (what type of request are we making?) in the `form_tag` provided in the view. Use 
the Rails URL helper method (ending in `_path`) for the route. Additionally, include an id field for the form tag 
with `tmdb_form`. 

Now, all is dandy, and we can supposedly search movies in the TMDb. But there is no way we can go to and return back 
to the home page without manually changing the URI. On the home page, add a button (or link) that will take the user 
to the search page, and in the search view add a button (or link) to bring them back to the homepage. Take a look at 
how users navigate back in the existing view `show.html.erb` for inspiration. Do we have all the necessary pieces to 
go to `/search` now? (You may need to wait until [Part 2](Part-2.md) before you can try this in your own browser).

## Starting Testing

In the MVC architecture, the controller's job is to respond to a user interaction, call the appropriate model method(s) 
to retrieve or manipulate any necessary data, and generate an appropriate view. We might therefore describe the 
_desired_ behavior of our as-yet-nonexistent controller method as follows:

1. We expect that our controller method would call a model method to perform the TMDb search, passing it the search 
terms typed by the user.

2. Then, we expect the controller method to select the correct view template (Show Search Results) for rendering.

3. Finally, we expect it to make the actual search results available to that template.

Note that none of the methods or templates in this list of desiderata actually exists yet! That is the essence of TDD: 
write a concrete and concise list of the desired behaviors (the spec), and use it to drive the creation of the methods 
and templates.

So, create the file `spec/controllers/movies_controller_spec.rb` containing the following, which corresponds to the 
three expectations articulated above. (By convention over configuration, RSpec expects the specs for 
`app/controllers/movies_controller.rb` to live in `spec/controllers/movies_controller_spec.rb`; similarly for models.)

```ruby
require 'rails_helper'

describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    it 'calls the model method that performs TMDb search'
    it 'selects the Search Results template for rendering'
    it 'makes the TMDb search results available to that template' 
  end
end
```

Line 3 says that the following specs **describe** the behavior of the `MoviesController` class. Because this class has 
several methods, line 4 says that this first set of specs describes the behavior of the method that searches TMDb. 
As you can see, `describe` can be followed by either a class name or a descriptive documentation string, and 
`describe` blocks can be nested. As we'll see later, nesting allows grouping sets of related examples that share some 
of the same setup or teardown code.

The next three lines are placeholders for what RSpec calls **examples**, a short piece of code that tests _one_ 
specific behavior. We haven't written any test code yet, but we can execute these test skeletons.

There are three ways to do so (try them now):

1. Running `bundle exec rspec ` _filename_ runs the tests in a single file, such as `movies_controller_spec.rb` above.

2. Running `bundle exec rspec` with no arguments runs all the tests.

3. Running `bundle exec guard`. Once Guard is running, it will watch for changes to either your code or your RSpec 
files, and automatically re-run the specs it thinks might be affected. Guard has a bit of a learning curve that we
won't cover in detail here, but it is worth spending a bit of time to learn to use it.

For the rest of the exercise, we'll assume that when you change tests or code, either `guard` is running and you get 
immediate feedback, or you manually re-run the necessary specs.

In any case, you can see that examples (`it` clauses) containing no code are displayed in yellow as "pending".

As we know, in a Rails app the `params` hash is automatically populated with the data submitted in a form so that the 
controller method can examine it. Happily, RSpec provides a `get` method that simulates submitting a form to a 
controller action: the first argument is the action name (controller method) that will receive the submission, and the 
second argument is a hash that will become the `params` seen by the controller action. We can now write the first 
line of our first spec, but we must overcome a couple of hurdles just to get to the Red phase of Red--Green--Refactor.

## Next
[Part 2 - Getting the first spec to pass](Part-2.md)