package org.ajdapp.getawaycrew;

import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.net.Uri;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.graphics.Color;

public class MainActivity extends Activity {
 private WebView browser;
 private static final String HOME="https://getaway.ajdapp.org/";
 @Override public void onCreate(Bundle state) {
  super.onCreate(state);
  browser=new WebView(this);
  browser.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,ViewGroup.LayoutParams.MATCH_PARENT));
  browser.setBackgroundColor(Color.rgb(247,245,239));
  WebSettings settings=browser.getSettings();
  settings.setJavaScriptEnabled(true);
  settings.setDomStorageEnabled(true);
  settings.setAllowFileAccess(false);
  settings.setAllowContentAccess(false);
  settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
  browser.setWebChromeClient(new WebChromeClient());
  browser.setWebViewClient(new WebViewClient(){
   @Override public boolean shouldOverrideUrlLoading(WebView view,WebResourceRequest req) {
    Uri uri=req.getUrl();
    if("https".equals(uri.getScheme())&&"getaway.ajdapp.org".equals(uri.getHost()))return false;
    try { startActivity(new Intent(Intent.ACTION_VIEW,uri)); }catch(Exception ignored){}
    return true;
   }
  });
  setContentView(browser);
  browser.loadUrl(HOME);
 }
 @Override public void onBackPressed() {
  if(browser!=null&&browser.canGoBack())browser.goBack();
  else super.onBackPressed();
 }
 @Override protected void onDestroy() {
  if(browser!=null){browser.destroy();browser=null;}
  super.onDestroy();
 }
}
