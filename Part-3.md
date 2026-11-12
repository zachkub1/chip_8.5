# Part 3 - More controller behaviors

Returning to our original specfile skeleton, the next spec says that `search_tmdb` should select the "Search Results" 
view for rendering. 

> [!NOTE]
> You could argue that since the default view is determined by convention over configuration, testing that the 
> "Search Results" view is selected for rendering is really just testing Rails' built-in functionality. But if we 
> were rendering different views depending on whether the action succeeded or failed, examples like this would verify 
> that the correct view was selected.

## Verifying that the correct view is selected for rendering

Since Rails' default behavior is to attempt to render a view whose name and path match the controller action, in this 
case `app/views/movies/search_tmdb.html.erb` (or `.html.haml` if you prefer), our spec just needs to verify that the 
controller action will indeed try to render that view template. To do this we will use the `response` method of 
RSpec-Rails: once we have done a `get` or `post` in a controller spec, the object returned by the `response` method 
will contain the app server's response to that action, and we can assert an expectation that the response 
**would have rendered** a particular view. Like the `get` method used in developing our controller spec, the 
`response` method is a facility provided by the `rspec-rails` gem, not by the core of RSpec itself.

In the code below that you can plug into the correct example, the _match condition_ for the expectation is supplied 
by `render_template()`, so the assertion is satisfied if the object (in this case the response from the controller 
action) attempted to render a particular view. We will see the use of `expect` with other match conditions later. The 
negative assertion `expect(...) to_not` (or its alias, `expect(...).not_to`) can be used to specify that the match 
condition should _not_ hold.

```ruby
it 'selects the Search Results template for rendering' do
  fake_results = [double('movie1'), double('movie2')]
  allow(Movie).to receive(:find_in_tmdb).and_return(fake_results)
  get :search_tmdb, params: { search_terms: 'hardware' }
  expect(response).to render_template('search_tmdb')
end
```

There are two things to notice here. First, since each of the two `it` examples are self-contained and Independent, we 
have to create the test doubles and perform the `get` command separately in each. We will shortly see a way to DRY out 
this repetition. Second, whereas the first example uses `expect`, the second example uses `allow`, which specifies that 
the test double method **may** be called but **doesn't** establish an expectation that that method **must** be called. 
The double springs into action **if** the method is called, but it's not an error if the method is never called.

In this simple example, you could argue that we're splitting hairs by using `expect` in one example and `allow` in 
another, but the goal is to illustrate that _each example should test a single behavior._ This second example is _only_ 
checking that the correct view is selected for rendering. It's _not_ checking that the appropriate model method gets 
called---that's the job of the first example. In fact, even if `Movie.find_in_tmdb` were implemented already, we'd 
still stub it out in these examples, because examples should isolate the behaviors under test from the behaviors of 
other classes with which the subject code collaborates.

## DRY out specs by refactoring common code into a `before` block

Before we write another example, we consider the Refactor step of Red--Green--Refactor. Modify your controller spec 
file to look like this (but don't remove the monkey-patching code if you added it earlier!):

```ruby
require 'rails_helper'

describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    before :each do
      @fake_results = [double('movie1'), double('movie2')]
    end
    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb).with('hardware').
        and_return(@fake_results)
      get :search_tmdb, params: { search_terms: 'hardware' }
    end
    it 'selects the Search Results template for rendering' do
      allow(Movie).to receive(:find_in_tmdb).and_return(@fake_results)
      get :search_tmdb, params: { search_terms: 'hardware' }
      expect(response).to render_template('search_tmdb')
    end
    it 'makes the TMDb search results available to that template'
  end
end
```

As the new code above implies, there is now a setup block that is executed before **each** of the examples within 
the `describe` group, similar to the `Background` section of a Cucumber feature, whose steps are performed before 
each scenario. (There is also `before(:all)`, which runs setup code just once for a whole group of tests; but you 
risk making your tests dependent on each other by using it, since it's easy for hard-to-debug dependencies to creep in 
that are only exposed when tests are run in a different order or when only a subset of tests are run.)

While the concept of factoring out common setup into a `before` block is straightforward, we had to make one syntactic 
change to make it work, because of the way RSpec is implemented. Specifically, we had to change `fake_results` into an 
instance variable `@fake_results`, because local variables occurring inside each example aren't visible outside that 
example. In contrast, instance variables of an example group are visible to all examples in that group. Since we are 
setting the value in the `before :each` block, every test case will see the same initial value of `@fake_results`.

<details>
  <summary>
  What kind of object do you think <code>@fake_results</code> is an instance
  variable of? (Put another way, what do you think is the value of
  <code>self</code> inside a block of test code?)
  </summary>
  <p><blockquote>
  It's an instance variable not of the class under test
  (<code>MoviesController</code>), but
  of the <code>Test::Spec::ExampleGroup</code> object that
  represents a group of test cases. 
  </blockquote></p>
</details>
<br />

## Verifying that the controller assigns correct view variables

We started with a list of three descriptions of desired behaviors in our controller action:

```ruby
describe 'searching TMDb' do
  it 'calls the model method that performs TMDb search'
  it 'selects the Search Results template for rendering'
  it 'makes the TMDb search results available to that template'
end
```

There's just one example left to write, to check that the TMDb search results will be made available to the response view.

The RSpec `assigns()` method keeps track of what instance variables were assigned in the controller method. Hence 
`assigns(:movies)` returns whatever value (if any) was assigned to `@movies` by the controller action, and our spec 
just has to verify that the controller action correctly sets up this variable.

Once again, we will take advantage of doubles. In our case, we've already arranged to return our doubles as the result 
of the faked-out method call, so the correct behavior for `search_tmdb` would be to set `@movies` to this value. Doing 
so and factoring out the common code between the second and third specs into their own nested `describe` gives us this 
final version of the controller spec. We chose the description string "after valid search" to name this nested 
`describe` block because the examples in this subgroup all assume that a valid call to `find_in_tmdb` has occurred; 
that assumption itself is tested by the first example. When example groups are nested, any `before` blocks associated 
with the outer nesting are executed prior to those associated with the inner nesting. So, for example, considering the 
test case in lines 18--20 below, the setup code in lines 5--7 is run first, followed by the setup code in lines 14--17, 
and finally the example itself (lines 18--20).

```ruby
require 'rails_helper'

describe MoviesController, type: :controller do
    describe 'searching TMDb' do
      before :each do
        @fake_results = [double('movie1'), double('movie2')]
      end
      it 'calls the model method that performs TMDb search' do
        expect(Movie).to receive(:find_in_tmdb).with('hardware').
         and_return(@fake_results)
        get :search_tmdb, params: { search_terms: 'hardware' }
     end
     describe 'after valid search' do
       before :each do
         allow(Movie).to receive(:find_in_tmdb).and_return(@fake_results)
         get :search_tmdb, params: { search_terms: 'hardware' }
       end
       it 'selects the Search Results template for rendering' do
         expect(response).to render_template('search_tmdb')
       end
       it 'makes the TMDb search results available to that template' do
         expect(assigns(:movies)).to eq(@fake_results)
       end
     end
   end
 end

```

Strictly speaking, for the purposes of this example the stubbed `find_in_tmdb` could have returned any value at all, 
such as the string "I am a movie", because the _only_ behavior tested by this example is whether the correct instance 
variable is being set up and made available to the view. In particular, this example doesn't care what the value of 
that variable is. But since we already had doubles set up, it was easy enough to use them in this example.

**Summary of this part:**

* An example of the Refactor step of Red--Green--Refactor is to move common setup code into a `before` block, thus 
DRYing out your specs.
* Method stubbing with `allow(...).to receive` creates a "test double" method for use in tests, but unlike 
`expect(...).to receive`, doesn't require that the method actually be called.
* `assigns()`, an RSpec-Rails extension, allows a controller test to inspect the values of instance variables set
by a controller action.

<details>
  <summary>
  Specify whether each
  of the following RSpec constructs is used to (a) 
  create a seam, (b) determine the behavior of a seam, (c)
  neither: (1) <code>assigns()</code> (2) <code>receive</code> (3) <code>expect</code> 
  (4) <code>and_return</code>
  </summary>
  <p><blockquote>
       (1) c, (2) a, (3) b, (4) b
  </blockquote></p>
</details>
<br />

<details>
  <summary>
  Why is it usually preferable to use <code>before(:each)</code> rather than
  <code>before(:all)</code> ?
  </summary>
  <p><blockquote>
    <code>before(:each)</code> is run before each spec in that
    block, setting up identical preconditions for all those specs and
    thereby keeping them Independent.
  </blockquote></p>
</details>
<br />

## Next
[Part 4 - TDD for the Model](Part-4.md)