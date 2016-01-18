package com.innoquant.mocaapp;

import android.location.Location;

import java.util.List;

/**
 * Created by Ivan on 7/1/16.
 */
public interface HekaergeListener {

    /**
     * Called when device has changed location
     * @param locations is a distance sorted list of locations
     */
    public void locationDidChange(List<HkLocation> locations);
}
