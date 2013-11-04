Apps 
===
Lots of people have been asking stuff...

!

My story
===
* Wasted +1yr on first app
* First few failed
* Since then churn out simple ones
* Been focused a few months maybe?
* 7 or 8 apps now

!

Sales
===
* Money's kinda useful
* Average $70/day
* Soon to be $100 with voda app
* Thats 36k...
* I want a boat

!

Coding
===
* Obj-C is nice
* Think of it like a VERY simple layer of OO on top of C
* Much simpler than C++
* Like JS with C syntax

!

Time and Motivation
===
* I spend a few hours a week on it
* Motivated by family/house
* Dont be scared to give it a go

!

Support
===
* I have my email in most apps
* Get maybe one a day?
* Everyone is friendly
* I gave one refund

!

Fail forwards
===
* Most apps fail
* < $5 / week = fail
* So: Make lots of small apps
* Build on what works eg usage
* Remember rovio made 51 apps before angry birds.

!

Ideas
===
* Start with crummy ideas. Thats better than nothing.
* If it's 'obvious' to you, then its probably useful to someone.
* Execution > ideas anyway.

!

Marketing
===
* Tried free for a week - fail (800 -> 0)
* I have websites for my apps - nothing
* Tried $2 - nothing, except usage apps
* Now I just plonk them on at $1 or $2 and leave it
* Haven't tried adwords

!

Nuts n bolts
===
* Reviews take 2 weeks
* Apple takes 30%
* GST is 10%
* Marginal tax will take 37% of what remains
* Put it in the wife's name!
* Ads in apps make nothing

!

Ideas
---
* Pair up, make two apps, one in each name to make revenue split simple
* Android - never touched. Get in the ground floor on tablets?
* Scratch your own itch - make a very simple app

!

Whats stopping you?
---
Any questions?



!
Markdown Presenter
===

This is what I use for giving simple, quick-to-produce presentations. Rather than fighting with keynote or powerpoint for hours, I can whip up a presentation in minutes using markdown.


!
Demo and usage
---
Check out a demo
[here](http://jsakamoto.github.com/MarkdownPresenter/Presenter.html).

!
#### Supported devices and browsers
Markdown Presenter may work well on iPhone/iPad, Android, and PC Desktop browsers (Chrome, Firefox, IE - if you want touch support, you can chose IE10 on Windows8 -).  
![slide index at dropdown](http://jsakamoto.github.io/MarkdownPresenter/iphone.png)

!
#### Switching between slides
Use the **arrow keys** on your keyboard or **swipe horizontally** on touch screen to switch between slides.

!
#### Reloading
You can reload the presentation at any time - staying on the same
slide number - by pressing the spacebar.

!
#### Transition effect
If you whould like to get fade in/out effect on switching between slides, type 'e' then 'f' key on your keyboard.  
To reset this transition effect, type 'e' then 'n'.

!
#### Direct page jump
You can jump to the any slide which you want to show directly by 3 ways as follow:

!

1. by PowerPoint compatibe keyboard shortcut, such as '2','1','Enter' then jump to the slide at 21.
2. by chosing slide index from drop down list at bottom-right of the browser window.  
![slide index at dropdown](http://jsakamoto.github.io/MarkdownPresenter/slide-index-at-dropdown.png)
3. by specification hash tag of URL.  
![slide index at hashtag](http://jsakamoto.github.io/MarkdownPresenter/slide-index-at-hashtag.png)


!
Installing
---
You need to install this on a web server, otherwise it won't be able
to open the presentation.md file via AJAX. So, if you're on a Mac,
copy it to your `~/Sites/MyPresentation` folder. Then open your web
browser to http://localhost/~myusername/MyPresentation/Presenter.html.

!

On Linux or Mac you have also likely Python installed and can start
its built-in web server in this directory by running `python -m SimpleHTTPServer`.

!

If you use [IIS](http://www.iis.net/) or [IIS express](http://www.iis.net/learn/extensions/introduction-to-iis-express/iis-express-overview) copy all the MarkdownPresenter files to the webfolder (normally `C:\Inetpub\wwwroot\<SiteFolder>` on IIS and `C:\Users\<User>\Documents\My Web Sites\<WebSite>` on IIS express). 

!

Also make sure that a MIME mapping for the .md extension is added. Either add the following mimeMap element to the `applicationhost.config` or the `web.config` file:

!

    <system.webServer>
      <!-- there might be other configuration here. -->
      <staticContent>
        <!-- there might be other configuration here. -->
        <mimeMap fileExtension=".md" mimeType="text/plain" />
      </staticContent>
    </system.webServer>

!
Markdown file
---
The presentation.md file is where you put your presentation. All you need to do to separate slides is a paragraph with an exclamation mark, eg:

!

    This is a slide
    Blah blah blah

    !

    This is another slide
    Yada yada yada

!
Printing Support
---

Markdown Presenter can print out the all slides to any printer from browser printing feature. 

![printing](http://jsakamoto.github.io/MarkdownPresenter/printing.png)

!

The keys to get fine result is follow:

- Layout - Landscape
- Margins - No margin
- Options - Enable to printing background colors

And you can print out as a PDF file, so you can also upload and publish your slides to "slideshare.com".

!
How it works
------------
The `Presenter.html` fetches the `presentation.md` from the server via
Ajax, uses [Showdown.js](https://github.com/coreyti/showdown) to
transform it into HTML, splits it on `<p>!</p>` into individual
slides, and displays the current slide.

!

Note: Showdown
[supports custom extensions](https://github.com/coreyti/showdown#creating-markdown-extensions)
that can either
[replace](https://github.com/coreyti/showdown#regexreplace) parts of
the content based on a regular expression or
[transform the whole text](https://github.com/coreyti/showdown#filter).
There are some
[extensions already available](https://github.com/coreyti/showdown/tree/master/src/extensions),
for example
[prettify](https://github.com/coreyti/showdown/blob/master/src/extensions/prettify.js)
that adds support for syntax highlighting or
[support for tables](https://github.com/coreyti/showdown/blob/master/src/extensions/table.js).

!

The current version of the bundled Showdown.js is 0.3.1 from Nov 2012.

!

Related
-------
- [Reveal.js](https://github.com/hakimel/reveal.js/): full-featured
  HTML+JS presentation framework with support for Markdown in
  individual slides
- [PageDown](http://code.google.com/p/pagedown/wiki/PageDown) - Stack
  Overflow's clone of Showdown

