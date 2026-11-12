# Submission Instructions

You will be tested on both correctness and testability of your app. Deploy your app to Heroku or Render (or really any
PaaS service) using the same technique as in CHIP 5.3 (you may need a force push!). You should set up the database as 
well, running the appropriate database setup commands on the PaaS server (Heroku or Render). 

Once you are confident the functionality works correctly on your desired platform, add the URI of your deployed app in
a text file called `rottenpotatoes-url.txt` with no other contents. Commit this file to the top level directory of your
repo.

> [!WARNING]
> Please be careful to use **https** and not **http**, that is, submit `https://your-app.herokuapp.com` 
> **and NOT** `http://your-app.herokuapp.com`.

You will only see a subset of failing tests, however you will still be able to see your final grade. To get full 
points we encourage to write your own tests. Looking into TMDb APIs more thoroughly and fuzz testing could be good 
approach in finding bugs in your app.

If you have correctly implemented the filtering and adding functions, **submitting to Gradescope and running the 
autograder will make changes to your deployed database**. Subsequent runs of the Gradescope autograder may not earn 
full credit, because the movies added to your database will be filtered out of search results in the future. One easy 
way to reset your database is just to destroy and re-create your app's database add-on before re-submitting 
to the autograder:

```sh
heroku addons:destroy heroku-postgresql -a <YOUR_APP_NAME>
heroku addons:create heroku-postgresql -a <YOUR_APP_NAME>
heroku run rails db:migrate
heroku run rails db:seed
```
