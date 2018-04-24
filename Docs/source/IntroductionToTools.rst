IntroductionToTools
=====================

This Matlab project uses several tools that I expect the average Matlab user might not be fluent with. Therefore, this page explain why those tools are necessary and how they can be effectively used. This page has three sections, namely, coding style, documentation and testing. First up is the coding style.

Coding Style
------------

Matlab is often used for scripts that serve one function. The script is started and runs from top to bottom, this is referred to as Procedure Oriented Programming or POP. Since FLORIS is not so straightforward and can perform several functions depending on the context POP is not the most applicable design philosophy. FLORIS is written using Object Oriented Programming (OOP) instead, a small write-up on the different strategies can be found `on the Matlab site <https://nl.mathworks.com/help/matlab/matlab_oop/why-use-object-oriented-design.html#brli27u>`_. In object oriented programming the main functionality of the code is contained in objects instead of functions. This allows the code to be more modular and, in the case of FLORIS, allows it to work as a control algorithm or an estimator.

Documentation
-------------
The documentation of FLORIS consists of this document you now have in front of you. It broadly consist of two interacting parts. Namely, the comments in the code and additional pages with information about the background and architecture and design strategies and such. Both the comments and these additional pages are written in a markup language called reStructuredText (RST), the full details of this language can be found `here <http://docutils.sourceforge.net/rst.html>`_, there is a `quick introduction <http://docutils.sourceforge.net/docs/user/rst/quickref.html>`_ as well. RST is basically an easy way to specify headings, paragraphs, lists, hyperrefs and more.

All the documentation is written in RST, to actually compile all this information into one document a tool called sphinx is used. `Sphinx <http://www.sphinx-doc.org/en/master/>`_ takes all the pages in the /FLORISSE_M/Docs/source folder and compiles them into the document you are reading. The end result is a dynamically generated document that can compile to html, pdf or epub. It can reference either the code of FLORIS or native Matlab functions and the object specifications can be easily and dynamically referenced and displayed in this documentation.

If you are programming on FLORIS you need not worry about this at all. If you don't use RST but simple plain text in your comments everything will still work out fine. As soon as a new piece of your code is accepted in the main repository this documentation will automatically recompile and update itself. Concluding, for people who do not worry about documentation nothing changes. For people who do worry about documentation a lot of options are now available to make good documentation including the use of latex style equations in comments in the code.

Testing
-------
The goal is to have 100% testing coverage of the code. The testing happens on several levels. The first level is the unit test, a small piece of code to test one method or function. Then there are integration tests on several levels. Checking to make sure that the interactions between objects work and checking that the final result of the entire code such as power prediction are correct.

When new code is written the unit tests can be run to see if any of the new code breaks all code. Travis CI is a free and open source service to do this kind of testing but alas, they do not have access to Matlab. For this reason FLORIS uses a `Jenkins <https://jenkins.io/>`_ server run on the TU Delft to run automated testing on new commits in the git repository.
