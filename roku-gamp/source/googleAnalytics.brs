' *********************************************************
' ** Google Analytics Measurement Protocol for Mobile App Analytics
' **
' ** Because this may be used often, we want to be as minimally
' ** invasive as possible.  For this reason we skip the NewHttp
' ** helper functions and instead manually construct the URI.
' **
' *********************************************************

' *********************************************************
' ** The MIT License (MIT)
' **
' ** Copyright (c) 2016 Christopher D Thompson
' **
' ** Permission is hereby granted, free of charge, to any person obtaining a copy
' ** of this software and associated documentation files (the "Software"), to deal
' ** in the Software without restriction, including without limitation the rights
' ** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' ** copies of the Software, and to permit persons to whom the Software is
' ** furnished to do so, subject to the following conditions:
' **
' ** The above copyright notice and this permission notice shall be included in all
' ** copies or substantial portions of the Software.
' **
' ** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' ** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' ** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' ** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' ** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' ** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

' *********************************************************


'*****************************
'** Initialization and request firing
'*****************************
Function initGAMobile(tracking_ids As Dynamic, client_id As String, custom_session_params={} As Object) As Void
  gamobile = CreateObject("roAssociativeArray")

  if type(tracking_ids) <> "roArray" then
    tracking_ids = [tracking_ids]
  endif

  ' Set up some invariants
  gamobile.url = "http://www.google-analytics.com/collect"
  gamobile.version = "1"
  gamobile.tracking_ids = tracking_ids
  gamobile.next_z = 1

  ' Default session params
  app_info = CreateObject("roAppInfo")
  device = createObject("roDeviceInfo")
  gamobile.session_params = {
    an: Box(app_info.GetTitle()).Escape()        ' App name.
    av: Box(app_info.GetVersion()).Escape()      ' App version.
    aid: Box(app_info.GetID()).Escape()          ' App Id.
    cid: Box(client_id).Escape()                 ' Client Id
    aiid: Box(device.getModel()).Escape()        ' App Installer Id.
  }

  ' Allow any arbitrary params to be sent with the hits
  if custom_session_params <> invalid and type(custom_session_params) = "roAssociativeArray" then
    gamobile.session_params.append(custom_session_params)
  end if

  ' single point of on/off for analytics
  gamobile.enable = false
  gamobile.asyncReqById = {}    ' Since we async HTTP metric requests, hold onto objects so they dont go out of scope (and get killed)
  gamobile.asyncMsgPort = CreateObject("roMessagePort")

  gamobile.debug = false

  'set global attributes
  m.gamobile = gamobile
End Function

Function enableGAMobile(enable As Boolean) As Void
  m.gamobile.enable = enable
End Function

Function getGaPendingRequestsMap() as Object
  return m.gamobile.asyncReqById
End Function

Function setGADebug(enable As Boolean) As Void
  m.gamobile.debug = enable
End Function

'*****************************
'** Hit types
'*****************************

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' PageView is primarily intended for web site tracking but is included here for completeness.
'
' | Parameter | Value Type  | Default Value | Max Length
' ------------------------------------------------------
' | hostname  | text        | None          | 100 Bytes
' | page      | text        | None          | 2048 Bytes
' | title     | text        | None          | 1500 Bytes
'
Function gamobilePageView(hostname="" As String, page="" As String, title="" As String) As Void
  if m.gamobile.debug
    ? "[GA] PageView: " + page
  end if
  
  hit_params = {
    t: "pageview"
    dh: Box(hostname).Escape()   ' Document hostname
    dp: Box(page).Escape()       ' Page
    dt: Box(title).Escape()      ' Title
  }
  gamobileSendHit(hit_params)
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Use the Event for application state events, such as a login or registration.
'
' | Parameter | Value Type  | Default Value | Max Length
' ------------------------------------------------------
' | category  | text        | None          | 150 Bytes
' | action    | text        | None          | 500 Bytes
' | label     | text        | None          | 500 Bytes
' | value     | integer     | None          | None
'
Function gamobileEvent(category As String, action As String, label="" As String, value="" As String) As Void
  if m.gamobile.debug
    ? "[GA] Event: " + category + "/" + action
  end if

  hit_params = {
    t: "event"
    ec: Box(category).Escape()   ' Event Category. Required.
    ea: Box(action).Escape()     ' Event Action. Required.
  }
  if label <> "" then hit_params.el = Box(label).Escape()      ' Event label.
  if value <> "" then hit_params.ev = Box(value).Escape()      ' Event value.
  gamobileSendHit(hit_params)
End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Use the ScreenView for navigation of screens.  This is useful for identifying popular
' categories or determining conversion rates for a video stream.
'
' | Parameter   | Value Type  | Default Value | Max Length
' ------------------------------------------------------
' | screen_name | text        | None          | 2048 Bytes
'
Function gamobileScreenView(screen_name As String) As Void
  if m.gamobile.debug
    ? "[GA] Screen: " + screen_name
  end if

  hit_params = {
    t: "screenview"
    cd: Box(screen_name).Escape()                ' Screen name / content description.
  }
  gamobileSendHit(hit_params)
End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Use the Transaction for in-app purchases or launching a stream.  Some channel publishers may
' pay content owners based on number of plays and Transaction would easily track this.
'
' | Parameter       | Value Type  | Default Value | Max Length
' -----------------------------------------------------------
' | transaction_id  | text        | None          | 500 Bytes
' | affiliation     | text        | None          | 500 Bytes
' | revenue         | currency    | 0             | None
' | shipping        | currency    | 0             | None
' | tax             | currency    | 0             | None
'
Function gamobileTransaction(transaction_id As String, affiliation="" As String, revenue="" As String, shipping="" As String, tax="" As String) As Void
  if m.gamobile.debug
    ? "[GA] transaction: " + transaction_id
  end if

  hit_params = {
    t: "transaction"
    ti: Box(transaction_id).Escape()  ' Transaction ID
  }
  if affiliation <> "" then hit_params.ta = Box(affiliation).Escape()   ' Transaction Affiliation
  if revenue <> "" then hit_params.tr = Box(revenue).Escape()           ' Transaction Revenue ("This value should include any shipping or tax costs" - Google)
  if shipping <> "" then hit_params.ts = Box(shipping).Escape()         ' Transaction Shipping
  if tax <> "" then hit_params.tt = Box(tax).Escape()                   ' Transaction Tax
  gamobileSendHit(hit_params)
End Function

Function gamobileItem() As Void
  'TODO: implement this
End Function

Function gamobileSocial() As Void
  'TODO: implement this
End Function

'**
'** Use Exception for reporting unexpected exceptions and errors. This is useful for identifying bad streams
'** or misbehaving CDNs.
'**
Function gamobileException(description As String) As Void
  if m.gamobile.debug
    ? "[GA] Exception: "
  end if
  
  hit_params = {
    t: "exception" 
    exd: Box(description).Escape()       ' Exception description.
    exf: "0"                          ' Exception is fatal? (we can't capture fatals in brightscript)
  }
  gamobileSendHit(hit_params)
End Function

Function gamobileTiming() As Void
  'TODO: implement this
End Function

' @hit_params   Associative array of params with string keys and values.  Values must already be urlencoded
Function gamobileSendHit(hit_params As Object) As Void
  if m.gamobile.enable <> true then
    if m.gamobile.debug
      ? "[GA] disabled. Skipping POST"
    end if
    return
  endif

  url = m.gamobile.url

  ' first set immutables  
  full_params = "v=" + tostr(m.gamobile.version)                ' Measurement Protocol Version

  ' next set session and hit params.  hit params can override session params
  merged_params = {}
  for each sp in m.gamobile.session_params
    merged_params[sp] = m.gamobile.session_params[sp]
  end for
  merged_params.Append(hit_params)

  for each mp in merged_params
    full_params = full_params + "&" + mp + "=" + merged_params[mp]
  end for

  For Each tracking_id in m.gamobile.tracking_ids
    'New xfer obj needs to be made each request and ref held on to per https://sdkdocs.roku.com/display/sdkdoc/ifUrlTransfer
    request = CreateObject("roURLTransfer")
    request.SetUrl(url)
    request.SetMessagePort(m.gamobile.asyncMsgPort)

    postStr = full_params + "&tid=" + Box(tracking_id).Escape()

    ' Cache buster; docs say this should be last
    postStr = postStr + "&z=" + tostr(m.gamobile.next_z)
    m.gamobile.next_z = m.gamobile.next_z + 1

    didSend = request.AsyncPostFromString(postStr)
    requestId = request.GetIdentity().ToStr()
    m.gamobile.asyncReqById[requestId] = request

    if m.gamobile.debug
      ? "[GA] sendHit POSTed ("+requestId+")";postStr
      ? "[GA] pending req";getGaPendingRequestsMap()
    end if
  End For

  gamobileCleanupAsyncReq()

End Function

' Garbage collect async requests that have completed
Function gamobileCleanupAsyncReq()
  For Each rid in m.gamobile.asyncReqById
    msg = m.gamobile.asyncMsgPort.GetMessage()
    if type(msg) = "roUrlEvent" and msg.GetInt() = 1    '1=xfer complete. We don't care about GetResponseCode() or GetFailureReason()
        requestId = msg.GetSourceIdentity().ToStr()   'Because we are sharing same port, get the request id
        m.gamobile.asyncReqById.Delete(requestId)
    end if
  End For

  if m.gamobile.debug
    ? "[GA] gamobileCleanupAsyncReq pending ";getGaPendingRequestsMap()
  end if
End Function
