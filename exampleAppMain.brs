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


'************************************************************
'** Application startup
'************************************************************
Function Main(args As Dynamic) As void

    gamobile_tracking_id = "tracking-id-here" ' tracking id for this channel
    gamobile_client_id = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"  'unique, anonymous, per-user id
    enable_tracking = true

    ' Init analytics
    initGAMobile(gamobile_tracking_id, gamobile_client_id)
    if enable_tracking then 
      print "Enabling tracking analytics"
      enableGAMobile(true)
    endif

    ' Track channel screens
    gamobileScreenView("Home")

    ' Track an event
    gamobileEvent("Registation", "Complete")

    ' Track an exception (unexpected state)
    gamobileException("metadata request returned HTTP status 404")

End Function

