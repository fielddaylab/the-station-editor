// mobile navigation
$(document).ready(function(){
  $('.mobile-nav-toggle').click(function(){
    $('.nav-contents').toggleClass('nav-open');
    $('.main-nav').toggleClass('nav-open');
  });

  $('.pane-open').click(function(){
    $('.create-with-siftr').toggleClass('open');
    $('#gettingstarted').toggleClass('open');
  });

  $('.pricing_block').click(function(){
    $(this).toggleClass('selected');
  });

  $('.search_bar').click(function(){
    $(this).toggleClass('selected');
  });

});

$(function() {
    // Call Gridder
    $('.gridder').gridderExpander({
        scroll: true,
        scrollOffset: 100,
        scrollTo: "panel",                  // panel or listitem
        animationSpeed: 900,
        animationEasing: "easeInOutExpo",
        showNav: true,                      // Show Navigation
        nextText: "Next",                   // Next button text
        prevText: "Previous",               // Previous button text
        closeText: "Close",                 // Close button text
        onStart: function(){
            //Gridder Inititialized
        },
        onContent: function(){
            //Gridder Content Loaded
        },
        onClosed: function(){
            //Gridder Closed
        }
    });
});

// smooth scroll
if (!window.location.pathname.match(/editor/)) {
  $(document).ready(function(){
    $('a[href^="#"]').on('click',function (e) {
        e.preventDefault();

        var target = this.hash;
        var $target = $(target);

        $('html, body').stop().animate({
            'scrollTop': $target.offset().top
        }, 1100, 'swing', function () {
            window.location.hash = target;
        });
    });
  });
}
