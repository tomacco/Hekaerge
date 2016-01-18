package com.innoquant.mocaapp;

import android.bluetooth.BluetoothAdapter;
import android.location.Location;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import com.innoquant.moca.MOCA;
import com.innoquant.moca.MOCABeacon;
import com.innoquant.moca.MOCAPlace;
import com.innoquant.moca.MOCAProximity;
import com.innoquant.moca.MOCAProximityService;
import com.innoquant.moca.MOCAZone;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * Created by Ivan on 7/1/16.
 * InnoQuant 2016
 */
public class Hekaerge implements MOCAProximityService.EventListener {
    final private String TAG = "Hekaerge";
    @NonNull
    final private List<HkLocation> mDefaultLocations;
    private HekaergeListener mListener;
    private List<HkLocation> mLastOrderedListLocations;
    @NonNull
    private List<MOCABeacon> mBeaconsInRange = new ArrayList<>();
    public Hekaerge(@NonNull List<HkLocation> locations) {
        mDefaultLocations = new ArrayList<>(locations);
        mLastOrderedListLocations = locations;
        MOCA.getProximityService().setEventListener(this);
        this.getLastKnownLocationByBeacons();
    }

    /**
     * Sort locations by distance to parameter. Reset to default if parameter
     * is null
     * @param location current location
     */
    private void orderListForLocation(@Nullable HkLocation location) {
        if(location == null){
            //reset to default
            mLastOrderedListLocations = new ArrayList<>(mDefaultLocations);
        }
        else{
            Collections.sort(mLastOrderedListLocations, new GeoComparator(location));
        }
        this.callListener();
    }

    /**
     * Returns location of the first beacon found with a known position, or null if
     * there are not known beacons in proximity (or there are no Locations in the found beacons).
     *
     * @return A beacon in range.
     */
    private HkLocation getLastKnownLocationByBeacons() {
        MOCAProximityService proxServ = MOCA.getProximityService();
        for (MOCABeacon b : proxServ.getBeacons()) {
            if (b.getProximity() != MOCAProximity.Unknown) {
                //Add beacon only if has valid coordenates
                if(this.addBeacon(b)) {
                    return beaconToHkLocation(b);
                }
            }
        }
        return null;
    }

    @NonNull
    private HkLocation beaconToHkLocation(@NonNull MOCABeacon b){
        Location beaconLoc = b.getLocation();
        return new HkLocation(b.getId(),
                beaconLoc.getLatitude(), beaconLoc.getLongitude(), b.getFloor(), 0.0);
    }

    /**
     * Adds a beacon to the beacons in Range only if it has a valid location
     * @param beacon to be added
     * @return true if is valid, false otherwise
     */
    private boolean addBeacon(@NonNull MOCABeacon beacon){
        if(beacon.getLocation() != null){
            Location bLoc = beacon.getLocation();
            double lat = bLoc.getLatitude();
            double lon = bLoc.getLongitude();
            if(lon != 0 && lat != 0){
                mBeaconsInRange.add(beacon);
                return true;
            }
        }
        return false;
    }

    //API

    @NonNull
    public List<HkLocation> getOrderedLocations() {
        if (this.isBluetoothOn()) {
            orderListForLocation(getLastKnownLocationByBeacons());
        }
        return mDefaultLocations; //send defaultLocations if bluetooth is off
    }

    public boolean isBluetoothOn() {
        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        return mBluetoothAdapter != null && mBluetoothAdapter.isEnabled();
    }

    public void setLocationChangeListener(HekaergeListener listener) {
        mListener = listener;
    }

    @NonNull
    public List<HkLocation> getDefaultLocations() {
        return mDefaultLocations;
    }

    //-------------------

    @Override
    public void didEnterRange(@NonNull MOCABeacon beacon, MOCAProximity proximity) {

        if(addBeacon(beacon)) {
            Collections.sort(mBeaconsInRange, new Comparator<MOCABeacon>() {
                @Override
                public int compare(@NonNull MOCABeacon beacon1, @NonNull MOCABeacon beacon2) {
                    if (beacon1.getProximity() == MOCAProximity.Unknown
                            ^ beacon2.getProximity() == MOCAProximity.Unknown) {
                        if (beacon1.getProximity() != MOCAProximity.Unknown) {
                            return -1;
                        }
                        return 1;
                    }
                    if (beacon1.getProximity().ordinal() < beacon2.getProximity().ordinal()) {
                        return -1; //1 is closer
                    }
                    if (beacon1.getProximity().ordinal() > beacon2.getProximity().ordinal()) {
                        return 1; //2 is closer
                    }
                    return 0;
                }
            });
            orderListForLocation(beaconToHkLocation(beacon));
        }

    }

    @Override
    public void didExitRange(MOCABeacon beacon) {
        if(mBeaconsInRange.contains(beacon)){
            mBeaconsInRange.remove(beacon);
        }
        if(mBeaconsInRange.size() == 0){
            this.orderListForLocation(null);
        }
        else{
            this.orderListForLocation(beaconToHkLocation(mBeaconsInRange.get(0)));
        }
    }

    private void callListener(){
        if (mListener != null) {
            mListener.locationDidChange(mLastOrderedListLocations);
        }
    }

    @Override
    public void didBeaconProximityChange(MOCABeacon beacon, MOCAProximity prevProximity, MOCAProximity curProximity) {

    }

    @Override
    public void didEnterPlace(MOCAPlace place) {

    }

    @Override
    public void didExitPlace(MOCAPlace place) {

    }

    @Override
    public void didEnterZone(MOCAZone zone) {

    }

    @Override
    public void didExitZone(MOCAZone zone) {

    }

    @Override
    public boolean handleCustomTrigger(String customAttribute) {
        return false;
    }

    @Override
    public void didLoadedBeaconsData(List<MOCABeacon> beacons) {

    }

    /**
     * Sort two locations by distance to another location
     */
    public class GeoComparator implements Comparator<HkLocation> {

        HkLocation currentLoc;

        public GeoComparator(HkLocation current) {
            currentLoc = current;
        }

        @Override
        public int compare(@NonNull final HkLocation loc1, @NonNull final HkLocation loc2) {
            double lat1 = loc1.getLatitude();
            double lon1 = loc1.getLongitude();
            double lat2 = loc2.getLatitude();
            double lon2 = loc2.getLongitude();

            //Log.d(TAG, "currentLoc: "+ currentLoc.getLatitude() + ", " + currentLoc.getLongitude());


            double distanceToLocation1 =
                    distance(currentLoc.getLatitude(), currentLoc.getLongitude(), lat1, lon1)
                    - loc1.getRadius();
            double distanceToLocation2 =
                    distance(currentLoc.getLatitude(), currentLoc.getLongitude(), lat2, lon2)
                    - loc1.getRadius();

            int diff = 0;

            if(distanceToLocation1 < 0 && distanceToLocation2 < 0){
                //Overlapping geofences
                //Policy: if same floor, smaller geofence location first
                if(loc1.getFloor() == loc2.getFloor()){
                    if(loc1.getRadius() < loc2.getRadius()){
                        diff = -1; //Loc1 i first
                    }
                    else if(loc1.getRadius() > loc2.getRadius()){
                        diff = 1; //Loc2 first
                    }
                }
            }
            //Regular cases
            else if(distanceToLocation1 < distanceToLocation2){
                diff = -1; //Loc1 i first
            }
            else if(distanceToLocation2 < distanceToLocation1){
                diff = 1; //Loc2 first
            }
            if(diff != 0){
                //Log.d(TAG, diff < 0 ? loc1.getId() + "closer than" + loc2.getId():
                 //       loc2.getId() + "closer than" + loc1.getId());
                return diff;
            }

            //same GPS coordinate && radius but distinct floor
            if (currentLoc.getFloor() == loc1.getFloor()){
                diff = -1; //Loc1 i first
            }
            else if(currentLoc.getFloor() == loc2.getFloor()){
                diff = 1; //Loc2 first
            }

            //Log.d(TAG, loc1.getId() + "same than" + loc2.getId());
            return diff;
        }

        // Great-circle distance algorithm
        public double distance(double fromLat, double fromLon, double toLat, double toLon) {
            double radius = 6378137;   // approximate Earth radius, *in meters*
            double deltaLat = toLat - fromLat;
            double deltaLon = toLon - fromLon;
            double angle = 2 * Math.asin(Math.sqrt(
                    Math.pow(Math.sin(deltaLat / 2), 2) +
                            Math.cos(fromLat) * Math.cos(toLat) *
                                    Math.pow(Math.sin(deltaLon / 2), 2)));
            return radius * angle;
        }
    }
}

