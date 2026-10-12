package com.tony.nubiaarcoretest;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import com.google.ar.core.ArCoreApk;
import com.google.ar.core.Session;
import java.io.PrintWriter;
import java.io.StringWriter;

public class MainActivity extends Activity {
    private TextView output;
    private Session session;
    private static final int SAVE_REPORT_REQUEST = 73;
    private void log(String message) { output.append(message + "\n"); }
    private void exception(Throwable e) {
        log("EXCEPTION: " + e.getClass().getName());
        log("MESSAGE: " + String.valueOf(e.getMessage()));
        StringWriter sw = new StringWriter();
        e.printStackTrace(new PrintWriter(sw));
        log("STACK TRACE:\n" + sw.toString());
        Throwable cause = e.getCause();
        while (cause != null) {
            log("CAUSE: " + cause.getClass().getName() + ": " + cause.getMessage());
            cause = cause.getCause();
        }
    }
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(24,24,24,24);
        Button test = new Button(this); test.setText("ESEGUI TEST ARCORE");
        Button copy = new Button(this); copy.setText("COPIA RAPPORTO");
        Button save = new Button(this); save.setText("SALVA RAPPORTO TXT");
        output = new TextView(this); output.setTextIsSelectable(true);
        ScrollView scroll = new ScrollView(this); scroll.addView(output);
        layout.addView(test); layout.addView(copy); layout.addView(save);
        layout.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
        setContentView(layout);
        test.setOnClickListener(v -> testAR());
        copy.setOnClickListener(v -> {
            ClipboardManager clipboard = (ClipboardManager)getSystemService(Context.CLIPBOARD_SERVICE);
            clipboard.setPrimaryClip(ClipData.newPlainText("ARCore diagnostics", output.getText().toString()));
            Toast.makeText(this, "Rapporto copiato", Toast.LENGTH_SHORT).show();
        });
        save.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("text/plain");
            intent.putExtra(Intent.EXTRA_TITLE, "nubia_arcore_report.txt");
            startActivityForResult(intent, SAVE_REPORT_REQUEST);
        });
        testAR();
    }
    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == SAVE_REPORT_REQUEST && resultCode == RESULT_OK && data != null) {
            Uri uri = data.getData();
            if (uri == null) return;
            try (OutputStream stream = getContentResolver().openOutputStream(uri)) {
                if (stream == null) throw new java.io.IOException("Impossibile aprire il file");
                stream.write(output.getText().toString().getBytes(StandardCharsets.UTF_8));
                Toast.makeText(this, "Rapporto TXT salvato", Toast.LENGTH_LONG).show();
            } catch (Exception e) {
                Toast.makeText(this, "Errore salvataggio: " + e.getMessage(), Toast.LENGTH_LONG).show();
            }
        }
    }
    private void testAR() {
        output.setText("NUBIA ARCORE TEST - REPORT\n");
        log("Manufacturer: " + Build.MANUFACTURER);
        log("Model: " + Build.MODEL);
        log("Device: " + Build.DEVICE);
        log("Product: " + Build.PRODUCT);
        log("Fingerprint: " + Build.FINGERPRINT);
        log("Android API: " + Build.VERSION.SDK_INT);
        try {
            log("ARCore availability: " + ArCoreApk.getInstance().checkAvailability(this));
        } catch (Throwable e) { log("Availability check failed:"); exception(e); }
        try {
            log("ARCore installed version: " + getPackageManager().getPackageInfo("com.google.ar.core",0).versionName);
        } catch (Exception e) { log("ARCore package query failed:"); exception(e); }
        if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            log("Camera permission missing. Grant it and run test again.");
            requestPermissions(new String[]{Manifest.permission.CAMERA}, 42);
            return;
        }
        try {
            if (session != null) { session.close(); session = null; }
            session = new Session(this);
            log("SUCCESS: ARCore Session created (tracking not tested).");
        } catch (Throwable e) {
            log("SESSION CREATION FAILED");
            exception(e);
        }
    }
    @Override protected void onDestroy() {
        if (session != null) session.close();
        super.onDestroy();
    }
}
