## helpful aliases ##

d = document


## some Chrome voodoo to set up the User-Agent Header override ##

IPHONE_USER_AGENT = 'Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25'

callback = (details) ->
    header.value = IPHONE_USER_AGENT for header in details.requestHeaders when header.name == 'User-Agent'
    requestHeaders: details.requestHeaders

filter = {urls: ['<all_urls>'], types: ['sub_frame']}
opt_extraInfoSpec = ['blocking', 'requestHeaders']

chrome.webRequest.onBeforeSendHeaders.addListener callback, filter, opt_extraInfoSpec


## state ##

state =
    tabs: []
    active_tab: null


## functions ##


save_state = ->
    data =
        urls: (tab.content.querySelector('iframe').src for tab in state.tabs[1..])
        active_tab_index: state.tabs.indexOf(state.active_tab)
    console.log 'Saving state:', data
    chrome.storage.sync.set data


load_state = ->
    chrome.storage.sync.get null, (data) ->
        console.log 'Loaded state:', data
        if data && data.urls
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
    button = d.createElement 'button'
    button.appendChild d.createTextNode url.replace /https?:\/\/(?:www|mobile|m\.)?(.*?)\.(?:com|gov|au\.uk|co\.in)\/?/, '$1'
    li.appendChild button
    d.getElementById('tabs').insertBefore li, d.getElementById 'plus-tab'

    tab =
        content: sec
        tab: li

    state.tabs.push tab

    button.addEventListener 'click', -> show_tab tab

    return tab


process_url = (url) ->
    if url.indexOf('http') != 0 then 'http://' + url else url


open_clicked = (event) ->
    url = d.getElementById('url').value
    show_tab create_new_tab process_url url
    save_state()


new_tab_clicked = (event) ->
    d.getElementById('url').value = ''
    show_tab state.tabs[0]
    d.getElementById('url').focus()


init_ui = (event) ->
    # add the “new” tab to the tabs array
    new_tab =
        content: d.getElementById 'new'
        tab: d.getElementById 'plus-tab'

    state.tabs.push new_tab

    # set up event listeners on default elements
    d.getElementById('open').addEventListener 'click', open_clicked
    d.getElementById('url').addEventListener 'keyup', (event) -> if event.keyCode == 13 then open_clicked()
    d.getElementById('plus-button').addEventListener 'click', new_tab_clicked

    load_state()


## add a listener to call init_ui once the DOM content is loaded ##

d.addEventListener 'DOMContentLoaded', init_ui

