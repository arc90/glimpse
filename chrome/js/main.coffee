## blacklist ##

# Many sites just don’t work with Glimpse, for various reasons
# We keep a list of a few of the big ones which are known not to work, so we can tell the user and let them abort

no_worky_tlds = ['gmail.com', 'twitter.com', 'facebook.com', 'googlemail.com', 'google.com']



## redirects ##

# Some sites don’t show their “mobile” sites based on the user agent, but only if you navigate specifically to
# m.tld.com or mobile.tld.com
# We keep a list of a few of the big ones so we can “redirect” automatically for the user

redirects =
    'http://nytimes.com': 'http://mobile.nytimes.com'
    'http://www.nytimes.com': 'http://mobile.nytimes.com'



## helpful aliases ##

d = document



## state ##

state =
    tabs: []
    urls: []
    active_tab: null



## modify HTTP requests and responses ##

IPHONE_USER_AGENT = 'Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25'

filter =
    urls: ['<all_urls>']
    types: ["main_frame", "sub_frame", "stylesheet", "script", "image", "object", "xmlhttprequest", "other"]

request_callback = (details) ->
    user_agent_header = (header for header in details.requestHeaders when header.name == 'User-Agent')[0]
    user_agent_header.value = IPHONE_USER_AGENT
    requestHeaders: details.requestHeaders

chrome.webRequest.onBeforeSendHeaders.addListener request_callback, filter, ['blocking', 'requestHeaders']


response_callback = (details) ->
    # remove the response header 'x-frame-options' so as to enable more sites to load in the iframe
    responseHeaders: header for header in details.responseHeaders when header.name.toLowerCase() isnt 'x-frame-options'

chrome.webRequest.onHeadersReceived.addListener response_callback, filter, ['blocking', 'responseHeaders']



## functions ##


save_state = ->
    data =
        urls: state.urls
        active_tab_index: get_active_tab_index()
    console.log 'Saving state:', data
    chrome.storage.sync.set data


get_tab_index = (tab) -> state.tabs.indexOf tab


get_active_tab_index = -> get_tab_index state.active_tab


load_state = ->
    chrome.storage.sync.get null, (data) ->
        console.log 'Loaded state:', data
        if data and data.urls
            create_new_tab url for url in data.urls
            if data.active_tab_index and state.tabs[data.active_tab_index]
                show_tab state.tabs[data.active_tab_index]


hide_tab = (tab) ->
    tab.content.style.display = 'none'
    tab.tab.className = 'tab inactive'


show_tab = (tab_to_show) ->
    # first hide all the other tabs
    hide_tab tab for tab in state.tabs when tab isnt tab_to_show

    # now show the specified tab
    tab_to_show.content.style.display = 'block'
    tab_to_show.tab.className = 'tab active'

    # TODO: it might be better to just shuffle the Z-axes of the tabs so the specified tab is on top

    # show the tab bar
    d.getElementById('tab-bar').style.display = 'block'

    state.active_tab = tab_to_show

    save_state()


# returns a tab, which is a object containing 2 properties: content and tab, which are both DOM elements
create_new_tab = (url) ->
    sec = d.createElement 'section'
    sec.className = 'tab-content'

    iframe = d.createElement 'iframe'
    iframe.src = url

    sec.appendChild iframe
    d.getElementById('tab-contents').appendChild(sec)

    li = d.createElement 'li'
    li.className = 'tab active'

    title_button = d.createElement 'button'
    title_button.appendChild d.createTextNode url.replace /https?:\/\/(?:www|mobile|m\.)?(.*?)\.(?:com|gov|au\.uk|co\.in)\/?/, '$1'
    li.appendChild title_button

    close_button = d.createElement 'button'
    close_button.className = 'close'
    close_button.appendChild d.createTextNode '×'
    li.appendChild close_button

    d.getElementById('tabs').insertBefore li, d.getElementById 'plus-tab'

    tab =
        content: sec
        tab: li

    state.tabs.push tab
    state.urls.push url

    li.addEventListener 'click', -> show_tab tab

    close_button.addEventListener 'click', (event) ->
        remove_tab tab
        # stop propagation because the button is within an li elem, and the li elem has a click listener for switching
        # to that tab (and the reason for that is to provide a large click target to the user)
        event.stopPropagation()

    return tab


remove_tab = (tab_to_remove) ->
    elem.parentNode.removeChild elem for elem in [tab_to_remove.content, tab_to_remove.tab]
    state.tabs = (tab for tab in state.tabs when tab.tab isnt tab_to_remove.tab)
    state.urls.splice get_tab_url_index(tab), 1
    # show_tab will save the state
    show_tab state.tabs[0]


get_tab_url_index = (tab) ->
    # need to subtract one from the active tab index because the first tab is always the “new tab” tab
    get_tab_index(tab) - 1


process_url = (url) ->
    cleaned_url =
        if url.trim().indexOf('http') isnt 0
            'http://' + url.trim().toLowerCase()
        else
            url.trim().toLowerCase()

    if cleaned_url of redirects
        redirects[cleaned_url]
    else
        cleaned_url


open_clicked = (event) ->
    url = d.getElementById('url')

    url_for_blacklist_checking = url.replace('http://', '').replace('https://', '').replace('www', '')

    matching_blacklist_tlds = (tld for tld in no_worky_tlds when string_starts_with_ignore_case(url_for_blacklist_checking, tld))

    url_in_blacklist = matching_blacklist_tlds.length > 0

    if url_in_blacklist
        matching_tld = matching_blacklist_tlds[0]
        show_error_message "Sorry, #{matching_tld} is known to be incompatible with Glimpse."
        return

    show_tab create_new_tab process_url url
    save_state()


string_starts_with_ignore_case = (a, b) -> a.toLowerCase().indexOf(b.toLowerCase()) is 0


show_error_message = (message) ->
    msg_elem = d.getElementById 'error_message'
    msg_elem.appendChild d.createTextNode message


clear_error_message = ->
    msg_elem = d.getElementById 'error_message'
    msg_elem.removeChild child for child in msg_elem.childNodes


new_tab_clicked = (event) ->
    d.getElementById('url').value = ''
    show_tab state.tabs[0]
    d.getElementById('url').focus()


# CoffeeScript syntax works better if the callback is the last arg
delay = (ms, func) -> setTimeout func, ms


init_ui = (event) ->
    # add the “new” tab to the tabs array
    new_tab =
        content: d.getElementById 'new'
        tab: d.getElementById 'plus-tab'

    state.tabs.push new_tab

    # set up event listeners on default elements
    d.getElementById('open').addEventListener 'click', open_clicked

    d.getElementById('url').addEventListener 'keyup', (event) ->
        clear_error_message()
        if event.keyCode == 13 then open_clicked()

    d.getElementById('plus-button').addEventListener 'click', new_tab_clicked

    load_state()

    # There’s a delay on this, unlike the other Chrome event listeners, because we don’t want to know about these events
    # when the popup first opens and load_state opens a bunch of tabs
    on_completed_callback = (details) -> update_current_tab_url details.url
    delay 1000, -> chrome.webRequest.onCompleted.addListener on_completed_callback, {urls: ['<all_urls>'], types: ['sub_frame']}


update_current_tab_url = (url) ->
    url_index = get_tab_url_index(state.active_tab)
    state.urls[url_index] = url
    save_state()



## add a listener to call init_ui once the DOM content is loaded ##

d.addEventListener 'DOMContentLoaded', init_ui
