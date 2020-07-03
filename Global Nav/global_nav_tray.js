////////////////////////////////////////////////////
// GLOBAL NAV TRAY                                //
////////////////////////////////////////////////////

/**
// @name        Global Nav - Custom Tray
// @namespace   https://github.com/robert-carroll/ccsd-canvas
// @author      Robert Carroll <carror@nv.ccsd.net>
//
// Pin by [Gregor Cresnar](https://thenounproject.com/grega.cresnar/) from [The Noun Project]
// https://creativecommons.org/licenses/by/3.0/
**/
$(document).ready(function() {
    ///* set tray title, icon, links and footer here *///
    ///*  for user role based conditions see README  *///
    var title   = 'Online Resources',
		svg     = 'https://eduridden.github.io/Canvas_Code/AIT/library.svg',
		// default links for all users
		trayLinks = [
			{ href: 'https://ait.instructure.com/courses/1970/announcements', svg_icon: 'link', title: 'Student News', desc:'Important updates and events for students' },
            { href: 'https://ait.instructure.com/courses/1972', svg_icon: 'link', title: 'College Library', desc:'Access the College Library services online' },
			{ href: 'https://redhill.freshdesk.com/', svg_icon: 'link', title: 'Online Learning Support', desc:'Got a problem? Contact support through the helpdesk' },
            { href: 'https://redhill.freshdesk.com/support/solutions', svg_icon: 'link', title: 'Self Help Guides', desc:'Help yourself with these great online guides' },
            { href: 'http://ait.checkfront.com/reserve', svg_icon: 'link', title: 'Lab Bookings - MLB', desc:'Book a space in a Melbourne Computer Lab' },
            { href: 'http://aitbookings.checkfront.com/reserve', svg_icon: 'link', title: 'Lab Bookings - SYD', desc:'Book a space in a Sydney Computer Lab' }
		],
		footer  = '<center><img src="https://eduridden.github.io/Canvas_Code/AIT/helpful_panda.png" width="110px" alt="Panda"></center><p>These links are provided to enable you with all the information you need to study online.</p>';
	
	// these links are appended to the tray by user role
    
	//if(ENV.current_user_roles.indexOf('teacher') >= 0 || ENV.current_user_roles.indexOf('admin') >= 0){
        //trayLinks.push({ href: 'http://www.example.com/your-library', title: 'Teacher Library', desc:'Optional text description' })
    //} else if (ENV.current_user_roles.indexOf('student') >= 0) {
        //trayLinks.push({ href: 'https://ait.instructure.com/courses/1962', title: 'Canvas Student Guide', desc:'Start here if you want to learn how to use Canvas better.' })
    //}
        
    ///* options are above for convenience, continue if you like *///
    var tidle     = title.replace(/\s/, '_').toLowerCase(),
        trayid    = 'global_nav_'+tidle+'_tray',
        trayItems = '',
        trayLinks = trayLinks.forEach(function(link) {
            trayItems += '<li class="gcnt-list-item">'
                      + '<span class="gcnt-list-link-wrapper">'
                      + '<a target="_blank" rel="noopener" class="gcnt-list-link" href="'+link.href+'" role="button" tabindex="0"><img src="https://eduridden.github.io/Canvas_Code/AIT/' + link.svg_icon + '.svg" style="width:10px; padding-right: 5px;">'+ link.title +'</a>'
                      + '</span>';
            // append link description if set
            if(!!link.desc && link.desc.length > 1)
                { trayItems +='<div class="gcnt-link-desc" style="padding-bottom: 5px;">'+ link.desc +'</div>' }
            trayItems += '</li>';
        }),
        
        // tray html
        tray = '<span id="'+trayid+'" style="display: none;">'
            + '<span class="global-nav-custom-tray gnct-easing">'
            + '<span role="region" aria-label="Global navigation tray" class="Global-navigation-tray">'
            // begin close button
            + '<span class="gcnt-tray-close-wrapper">'
            + '<button id="'+trayid+'_close" type="button" role="button" tabindex="0" class="gcnt-tray-close-btn" style="margin:0px;">'
            + '<span class="gcnt-tray-close-svg-wrapper">'
            + '<svg name="IconXSolid" viewBox="0 0 1920 1920" style="fill:currentColor;width:1em;height:1em;" width="1em" height="1em" aria-hidden="true" role="presentation" disabled="true">'
            + '<g role="presentation"><svg version="1.1" viewBox="0 0 1920 1920">'
            + '<path d="M1743.858.012L959.869 783.877 176.005.012 0 176.142l783.74 783.989L0 1743.87 176.005 1920l783.864-783.74L1743.858 1920l176.13-176.13-783.865-783.74 783.865-783.988z" stroke="none" stroke-width="1"></path>'
            + '</svg></g></svg><span class="gcnt-tray-close-txt">Close</span></span></button></span>'
            // end of close button; begin tray header
            + '<div class="tray-with-space-for-global-nav">'
            + '<div id="custom_'+tidle+'_tray" class="gnct-content-wrap">'
            + '<h1 class="gcnt-tray-h1">'+ title +'</h1><hr>'
            // end tray header; begin tray links list
            + '<ul class="gcnt-list">'
            + trayItems;
            // end tray links; if there is a footer, append it
            if(footer.length > 1) {
                tray += '<li class="gcnt-list-item"><hr></li>'
                      + '<li class="gcnt-list-item">'+ footer + '</li>';
            }
            // end tray html
            tray += '</ul></div></div></span></span></span>';
    // global nav icon
    var main = $('#main'),
        menu = $('#menu'),
        icon = $('<li>', {
            id: 'global_nav_'+tidle+'_menu',
            class: 'ic-app-header__menu-list-item',
            html: '<a id="global_nav_'+tidle+'_link" href="javascript:void(0)" class="ic-app-header__menu-list-link">'
              + '<div class="menu-item-icon-container" role="presentation"><span class="svg-'+tidle+'-holder"></span></div>'
              + '<div class="menu-item__text">' + title + '</div></a>'
            });
        icon.find('.svg-'+tidle+'-holder').load(svg, function(){
            var svg = $(this).find('svg')[0],
                svg_id = 'global_nav_'+tidle+'_svg';
                svg.setAttribute('id', svg_id);
                svg.setAttribute('class', 'ic-icon-svg menu-item__icon ic-icon-svg--apps svg-icon-help ic-icon-svg-custom-tray')
                $('#'+svg_id).find('path').removeAttr('fill')
        });
    menu.append(icon);
    main.append(tray);
    // if you ventured this far, please note variable reassignment
    icon = $('#global_nav_'+tidle+'_menu');
    tray = $('#'+trayid);

    // TODO: there's a delay in switching active icon states, sometimes both are active for a moment

    // multiple ways for the tray to get closed, reduce and reuse
    function close_gnct() {
        menu.find('a').each(function(){this.onmouseup = this.blur()})
        tray.find('.gnct-easing').animate({
            left: '-200px', opacity: .8
        }, 300, 'linear', function() {
            tray.hide()
            icon.removeClass('ic-app-header__menu-list-item--active')
        })
    }
    icon.click(function() {
        // if the tray is open, close it
        if($(this).hasClass('ic-app-header__menu-list-item--active')) {
            close_gnct()
        // else open the tray
        } else {
            menu.find('a').each(function(){this.onmouseup = this.blur()})
            tray.show()
            tray.find('.gnct-easing').animate({
                left: '0px', opacity: 1
            }, 300, 'linear', function() {
                $('.ic-app-header__menu-list-item').removeClass('ic-app-header__menu-list-item--active');
                icon.addClass('ic-app-header__menu-list-item--active');
            })
        }
    });
    // close the tray if the user clicks another nav icon that is not this one
    $('.ic-app-header__menu-list-item').not(icon).click(function() { close_gnct(); });
    // close the tray
    $('#'+trayid+'_close').click(function() { close_gnct(); });
});