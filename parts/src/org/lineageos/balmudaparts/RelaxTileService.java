/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.balmudaparts;

import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;

/** Relax mode Quick Settings tile. */
public class RelaxTileService extends TileService {
    @Override
    public void onStartListening() {
        refresh();
    }

    @Override
    public void onClick() {
        final GestureController controller = GestureController.get(this);
        controller.setRelaxEnabled(!controller.isRelaxEnabled());
        refresh();
    }

    private void refresh() {
        final Tile tile = getQsTile();
        if (tile == null) {
            return;
        }
        final boolean on = GestureController.get(this).isRelaxEnabled();
        tile.setState(on ? Tile.STATE_ACTIVE : Tile.STATE_INACTIVE);
        tile.setSubtitle(getString(on ? R.string.relax_tile_on : R.string.relax_tile_off));
        tile.updateTile();
    }
}
