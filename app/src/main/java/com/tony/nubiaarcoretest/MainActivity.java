package com.tony.nubiaarcoretest;

import android.app.Activity;
import android.os.Bundle;
import android.Manifest;
import android.content.pm.PackageManager;
import android.widget.TextView;
import android.widget.ScrollView;
import android.widget.Button;
import android.widget.LinearLayout;
import com.google.ar.core.ArCoreApk;
import com.google.ar.core.Session;

public class MainActivity extends Activity {
    private TextView output;
    private Session session;
    private void log(String s) { output.append(s + "\n"); }
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(32,32,32,32);
        Button test = new Button(this); test.setText("TEST ARCORE");
        output = new TextView(this); output.setTextIsSelectable(true);
        ScrollView scroll = new ScrollView(this); scroll.addView(output);
        layout.addView(test); layout.addView(scroll);
        setContentView(layout);
        test.setOnClickListener(v -> testAR());
        testAR();
    }
    private void testAR() {
        output.setText("Nubia ARCore diagnostics\n");
        try {
            log("ARCore availability: " + ArCoreApk.getInstance().checkAvailability(this));
            log("ARCore package installed: " + getPackageManager().getPackageInfo("com.google.ar.core",0).versionName);
            if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                log("Camera permission required. Grant and press TEST again.");
                requestPermissions(new String[]{Manifest.permission.CAMERA}, 42);
                return;
            }
            if (session != null) { session.close(); session = null; }
            session = new Session(this);
            log("SUCCESS: ARCore Session created.");
            log("Note: camera tracking not yet tested.");
        } catch (Exception e) {
            log("ERROR: " + e.getClass().getName());
            log("Message: " + e.getMessage());
            android.util.Log.e("NubiaARCoreTest","ARCore diagnostic failure",e);
        }
    }
    @Override protected void onDestroy() { if (session != null) session.close(); super.onDestroy(); }
}
