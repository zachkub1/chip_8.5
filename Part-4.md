# Part 4 - TDD for the Model

Next up we will use TDD to implement the model method `find_in_tmdb` that we've so far been stubbing out. Since 
this method is supposed to call the actual TMDb service, we will again need to use stubbing, this time to avoid having 
our examples depend on the behavior of a remote Internet service.

Like many SaaS applications, TMDb has a RESTful API that supports actions such as "search for movies matching a 
keyword" or "retrieve detailed information about a specific movie". To prevent abuse and track each user of the API 
separately, each developer wishing to make calls to the API must first obtain their own _API key_ by requesting one 
via the [TMDb website](https://developers.themoviedb.org/3/getting-started/introduction). API requests that do not 
include a valid API key are not honored, returning an error instead. For request URI's containing a valid API key, 
TMDb returns a JSON object as the result of the request encoded by the URI. This flow---construct a RESTful URI that 
may include an API key, receive a JSON response---is a common pattern for interacting with external services.

In general there are (at least) two ways to construct external API calls in Ruby: directly or using a library. The 
direct method would be to use the `URI` class in the Ruby standard library to construct the request URI, use the 
`Net::HTTP` class to issue the request to TMDb, check for errors in the response, and if all is well, and parse 
the resulting JSON object. But sometimes we can be more productive by standing on the shoulders of others, as we 
can in this case by using a library (or in the Ruby world, a gem). The gem `faraday` is an HTTP library that provides 
interface over `Net::HTTP`. There is also `themoviedb-api` gem, which is a user-contributed Ruby "wrapper" around 
TMDb's RESTful API, mentioned on the TMDb API documentation pages. Not every RESTful API has a corresponding Ruby 
library, so we will rely on Faraday to learn a general technique which can be used for all sorts of RESTful APIs. 

## Using the TMDb API directly

Whenever you set out to use a remote API, with or without a gem wrapper, you need to do some exploration to learn how 
the API works, and usually you'll need to get a developer API key as well, before even using the wrapper gem.

* Spend a few minutes exploring the interactive Web version of [The Movie DB](https://www.themoviedb.org/) to 
understand how you can do a search by movie title.

* Next, briefly check out its [API documentation](https://developers.themoviedb.org/3) using the skills you learned 
earlier in the course. In particular, familiarize yourself with the Search and Query for Details API calls.

* Apply for an API key and note it somewhere secure.

<details>
<summary>
  Suppose your API key was `5678`. Construct a URI that would call TMDb's search function to search for the 
  made-for-TV movie "This Life + 10". (Don't forget to <a href="https://en.wikipedia.org/wiki/Percent-encoding">
  escape nonalphanumeric characters in the URI</a>. Here are two <a href="https://www.url-encode-decode.com">online</a> 
  <a href="http://www.utilities-online.info/urlencode">tools</a> to help you do this. Ruby's 
  <a href="https://docs.ruby-lang.org/en/3.3/CGI/Escape.html"><code>CGI::Escape</code> module's 
  <code>escape</code> function</a> can also do this programmatically, as in 
  <code>puts CGI.escape('https://some.url.com/etc.')</code>.  (Be sure to use <code>require 'cgi'</code> to access the
  module!)
</summary>
<p>
<blockquote>
  <code>https://api.themoviedb.org/3/search/movie?api_key=5678&amp;query=this%20life%20%2B%2010</code> is the 
  official escaping, since hex 20 (decimal 32) is the ASCII code for a space character and hex 2B (decimal 43) is the 
  ASCII code for the "+" symbol. Another format that would work, because escaping a space in a URL is a special case
  shortcut, would be <code>https://api.themoviedb.org/3/search/movie?api_key=5678&amp;query=this+life+%2B+10</code>.
</blockquote></p>
</details>
<br/>

<details>
<summary>
  Use the <code>curl</code> command to actually issue this request to TMDb
  from a terminal using your real API key. What is the ID of the
  returned match?
</summary>
<blockquote>
  442668
</blockquote>
</details>

## Using Faraday

Now that you have a basic idea of the API call you're going to use, and an API key, you're ready to actually use Faraday.

<details>
<summary>
Before we start using Faraday, let's make sure we have a solid understanding on how to construct RESTful URIs for 
accessing movies in TMDb. Write two URIs that would make a <code>GET</code> request to TMDb. The first one should 
search for the movie Manhunter released on 1986 (i.e. include the title of the movie as well as the release year), 
and the second one should look for the movie Gone Girl with the language set to English. 
  </summary>
  <blockquote>
    URI1:
    <code>https://api.themoviedb.org/3/search/movie?api_key=9d9c894fdcbeb32f1d1b2ae2d8427402&amp;query=Manhunter&amp;year=1986</code><br>
    URI2:
    <code>https://api.themoviedb.org/3/search/movie?api_key=9d9c894fdcbeb32f1d1b2ae2d8427402&amp;query=Gone%20Girl&amp;language=en-US</code>
  </blockquote>
  
</details>
<br/>

<details>
 <summary>
Now, let's test our understanding of Faraday. How would we make a GET request using one of the URIs defined in the last step?
 </summary>
  <blockquote>
    <code>Faraday.get url</code> where url can be either one of the URIs we defined in the previous step.
  </blockquote>
</details>
<br/>

What's the return type of the Faraday <code>GET</code> request? Is it JSON? Well, almost. It's actually a stringified 
version of JSON, so once we get the results of the API call, we will need to parse them with <code>JSON.parse</code>. 
We usually store the result of an API call in <code>response</code> variable. To better understand the structure of 
the return JSON object, make a few API calls in your browser (just paste the URI into the search tab) and study the 
results. Then, answer the following questions.

<details>
<summary>
 What Ruby expression would return the first element in the list of matching movies?
</summary>
<blockquote>
  <code>response.results[0]</code> or <code>response.results.first</code>
</blockquote>
</details>
<br/>

<details>
<summary>
  What Ruby expression would set the variable <code>overview</code> to the first search result's movie summary?
</summary>
<blockquote>
  <code>overview = response.results[0].overview</code>
</blockquote>
</details>
<br/>

<details>
<summary>
  What Ruby expression would return the release date of the first search result, as a Ruby <code>Date</code> object? 
  (Hint: Rails has some <a href="https://guides.rubyonrails.org/active_support_core_extensions.html">convenient
  extensions</a> to help manage date and time objects.
</summary>
<blockquote>
   <code>Date.parse(response['results'][0]['release_date'])</code> or
   <code>response['results'][0]['release_date'].to_date</code>
</blockquote>
</details>
<br/>

<details>
  <summary>
    True or false: in order to use the TMDb API from another language such as Java, we would need a Java library 
    equivalent to `themoviedb-api` gem.
  </summary>
  <p><blockquote>
   False: the API consists of a set of HTTP requests and JSON responses, so as long as we can transmit and receive 
   bytes over the HTTP protocol and have the ability to parse strings (the JSON responses), we can use the APIs
   without a special library.
  </blockquote></p>
</details>
<br/>

<details>
  <summary>
  True or false: in order to use
  the TMDb API from another language such as Python, we would need a Python
  library equivalent to <code>themoviedb-api</code> gem.
  </summary>
  <p><blockquote>
    False: the API consists of a set of HTTP requests and JSON responses, so as long as we can transmit and receive 
    bytes over the HTTP protocol and have the ability to parse strings (the JSON responses), we can use the APIs 
    without a special library.
  </blockquote></p>
</details>
<br />

## Writing the model method and stubbing out TMDb's API

By convention over configuration, specs for the `Movie` model go in `spec/models/movie_spec.rb`. Here is the happy 
path for calling `find_in_tmdb` in the form of a model spec, and the one line of code necessary in the `Movie` 
class to make it pass.

```ruby
require 'rails_helper'

describe Movie do
  describe 'searching TMDB by keyword' do
    it 'calls Faraday gem with NYU domain' do
      expect(Faraday).to receive(:get).with('https://nyu.edu')
      Movie.find_in_tmdb('https://nyu.edu')
    end
  end
end
```

```ruby
class Movie < ApplicationRecord

  def self.find_in_tmdb(string)
    Faraday.get(string)
  end

  # rest of file elided for brevity
end
```

Notice that we don't really care if the right URL is passed to Faraday. In fact, what we provided wasn't even a URL. 
The point is, we are testing whether methods are being called and not whether the methods return the correct results 
or error out. 

You might wonder why the controller doesn't just call the `Faraday.get` method itself, rather than having that method 
"wrapped" in a model method `Movie.find_in_tmdb`. There are two reasons. First, if the Faraday gem's API changes, 
perhaps to accommodate a change to the TMDb service API itself, we can insulate the controller from those changes 
because all the knowledge of how to use the gem to communicate with the service is encapsulated inside the `Movie` 
class. This indirection is an example of separating things that change from those that stay the same. The second and 
more important reason is that this spec is subtly incomplete: `find_in_tmdb` has additional jobs to do. Our test cases 
have been based on the _explicit requirement_ that the user-provided name of a movie should be used to query TMDb. 
But in fact, querying TMDb requires a valid API key.

## Next
[Part 5 - Implementing find_in_tmdb, and Stubbing the Internet](Part-5.md)