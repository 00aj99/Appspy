package com.epfl.appspy.activity;

import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.support.v7.app.ActionBarActivity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;

import com.epfl.appspy.GlobalConstant;
import com.epfl.appspy.GlobalConstant.EXTRA_ACTION;
import com.epfl.appspy.LogA;
import com.epfl.appspy.R;
import com.epfl.appspy.Utility;
import com.epfl.appspy.monitoring.AppActivityTracker;
import com.epfl.appspy.monitoring.GPSTracker;
import com.epfl.appspy.monitoring.InstalledAppsTracker;

import java.io.File;
import java.io.IOException;


/**
 *
 *  Show activity where user can send DB or remove temp files
 *
 * */
public class DatabaseActivity extends ActionBarActivity {


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_database);
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_rights, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        if (id == R.id.action_settings) {
            Intent settingsActivity = new Intent(this,SettingsActivity.class);
            startActivity(settingsActivity);
            return true;
        }
        return super.onOptionsItemSelected(item);
    }


    @Override
    protected void onResume() {
        super.onResume();
        LogA.i("Appspy-MainActivity", "Show database activity");
    }


    /**
     * Send the DB
     */
    public void sendDB(View v){

        LogA.i("Appspy", "click on sendDB");
        try {
            String path = Environment.getExternalStorageDirectory().getAbsolutePath();
            String zipName = "appspy.zip";

            File zippedFolder = new File(path + "/tmp/" + zipName);

            //String dbPath = "/data/data/com.epfl.appspy/databases/Appspy_database";

            File originalDB = new File("data/data/com.epfl.appspy/databases/Appspy_database");
            File copiedDB = new File(path + "/" + GlobalConstant.APPSPY_TMP_DIR + "/db.db");

            //erase if exists
            copiedDB.delete();
            zippedFolder.delete();


            //if folver /tmp does not exists, create it
            File folderToZip = new File(path + "/" + GlobalConstant.APPSPY_TMP_DIR);
            if (folderToZip.exists() == false) {
                folderToZip.mkdir();
            }


            //Create a copy of the db file
            Utility.copyFile(originalDB, copiedDB);

            //zip the folder containing the db file and the log file
            Utility.zipFolder(folderToZip.getAbsolutePath(), zippedFolder.getAbsolutePath());

            //Send the file to an email client
            Uri uriFileToSend = Uri.parse("file://" + zippedFolder.getAbsolutePath());
            try {
                Intent intent = new Intent(Intent.ACTION_SENDTO); // it's not ACTION_SEND
                intent.setType("application/zip");
                intent.putExtra(Intent.EXTRA_SUBJECT, "Database");
                intent.putExtra(Intent.EXTRA_TEXT, "Here are the database and the logs");
                intent.setData(Uri.parse("mailto:zatixjo@gmail.com")); // or just "mailto:" for blank
                intent.putExtra(Intent.EXTRA_STREAM, uriFileToSend);

                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK); // this will make such that when user returns to your app, your app is displayed, instead of the email app.*/

                Intent chooserIntent = Intent.createChooser(intent, "Open in");
                startActivity(chooserIntent);

                LogA.d("Appspy", "before");
                //startActivity(intent);
            } catch (ActivityNotFoundException e){
                AlertDialog.Builder alert = new AlertDialog.Builder(this);
                alert.setTitle("Error");
                alert.setMessage("You need an email client that support attachments");
                alert.setPositiveButton("Ok", null);
                alert.show();
            }

        } catch (IOException e) {
            e.printStackTrace();
        }

    }


    /**
     * Compute the stats right now. For some, just setup the periodic check of the stat
     * @param v
     */
    public void computeStatNow(View v){

        Utility.startLogging();

        Log.d("Appspy","Request to compute stats now");

        //call the InstalledAppsTracker to check all installed apps
        Intent installedAppReceiver = new Intent(getApplicationContext(), InstalledAppsTracker.class);
        installedAppReceiver.setAction(Intent.ACTION_SEND);
        installedAppReceiver.putExtra(GlobalConstant.EXTRA_TAG, EXTRA_ACTION.MANUAL);
        sendBroadcast(installedAppReceiver);


        //Launch GPS (useful when app is installed and launched for the first time. After that, not useful
        //the service is started with the boot.
        Intent gpsTaskReceiver = new Intent(getApplicationContext(), GPSTracker.class);
        gpsTaskReceiver.setAction(Intent.ACTION_SEND);
        gpsTaskReceiver.putExtra(GlobalConstant.EXTRA_TAG, EXTRA_ACTION.MANUAL);
        sendBroadcast(gpsTaskReceiver);


        //Launch the app activity tracker it not already launched (or if crashed). Does nothing otherwise.
        Intent activityTaskReceiver = new Intent(getApplicationContext(), AppActivityTracker.class);
        activityTaskReceiver.setAction(Intent.ACTION_SEND);
        activityTaskReceiver.putExtra(GlobalConstant.EXTRA_TAG, EXTRA_ACTION.MANUAL);
        sendBroadcast(activityTaskReceiver);
    }


    /**
     * Remove the log file and the temporary file create when sending the db
     * @param v
     */
    public void removeTmpFiles(View v){
        String path = Environment.getExternalStorageDirectory().getAbsolutePath();
        String zipName = "appspy.zip";

        File zippedFolder = new File(path + "/tmp/" + zipName);
        zippedFolder.delete();


        File folderToDelete = new File(path + "/" + GlobalConstant.APPSPY_TMP_DIR);
        Utility.deleteFolder(folderToDelete);

        //restart logging as it stopped when removing the file
        Utility.startLogging();
    }

}
