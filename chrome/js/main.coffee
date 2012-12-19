## some Chrome voodoo to set up the User-Agent Header override ##


IPHONE_USER_AGENT = 'Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25'

callback = (details) ->
    header.value = IPHONE_USER_AGENT for header in details.requestHeaders when header.name == 'User-Agent'
    {requestHeaders: details.requestHeaders}

filter = {urls: ['<all_urls>'], types: ['sub_frame']}
opt_extraInfoSpec = ['blocking', 'requestHeaders']

chrome.webRequest.onBeforeSendHeaders.addListener callback, filter, opt_extraInfoSpec


## functions ##


create_new_tab = (url) ->
    sec = document.createElement 'section'
    sec.className = 'tab-content'

    iframe = document.createElement 'iframe'
    iframe.src = url

    sec.appendChild iframe
    document.getElementById('tab-contents').appendChild(sec)
    return sec


show_tab = (tab_to_show) ->
    # first hide all the other tabs
    tab.style.display = 'none' for tab in document.getElementById('tab-contents').children when tab isnt tab_to_show

    # now show the specified tab
    tab_to_show.style.display = 'block'

    # TODO: it might be better to just shuffle the Z-axes of the tabs so the specified tab is on top


process_url = (url) ->
    return 'http://' + url if url.indexOf('http') != 0
    url


open_url = (event) ->
    url = document.getElementById('url').value
    show_tab(create_new_tab(process_url(url)))


## set up event listeners on default elements ##

document.addEventListener 'DOMContentLoaded', (event) ->
    document.getElementById('open').addEventListener 'click', open_url
    document.getElementById('url').addEventListener 'keyup', (event) -> if event.keyCode == 13 then open_url()
