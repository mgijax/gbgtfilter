package org.jax.mgi.shr.config;

import org.jax.mgi.shr.config.Configurator;
import org.jax.mgi.shr.config.ConfigException;

/**
 * An object that retrieves Configuration parameters for the GBGeneTrapFilter
 * @has Nothing
 *   <UL>
 *   <LI> a configuration manager
 *   </UL>
 * @does
 *   <UL>
 *   <LI> provides methods to retrieve Configuration parameters that are
 *        specific to the GBGeneTrapFilter
 *   </UL>
 * @company The Jackson Laboratory
 * @author sc
 * @version 1.0
 */

public class GBGeneTrapFilterCfg extends Configurator {

    /**
    * Constructs a Genbank GeneTrap Filter Configuration object
    * @assumes Nothing
    * @effects Nothing
    * @throws ConfigException if a configuration manager cannot be obtained
    */

    public GBGeneTrapFilterCfg() throws ConfigException {
    }


    /**
     * Gets the map coordinate collection name 
     * @return the map coordinate collection name
     * @throws ConfigException if "COORD_COLLECTION_NAME" not found in configuration file
     */
    public String getMapCollectionName() throws ConfigException {
        return getConfigString("COORD_COLLECTION_NAME");
    }

    /**
     * Get the filename for writing gene trap sequence records which represent
     * ALOs not yet in the database
     * @assumes Nothing
     * @effects Nothing
     * @return the output file file name
     * @throws ConfigException if "NEW_OUTFILE_NAME" not found in configuration file
     */
    public String getNewOutputFileName() throws ConfigException {
        return getConfigString("NEW_OUTFILE_NAME");
    }

    /**
     * Get the filename for writing all gene trap sequence records 
     * @assumes Nothing
     * @effects Nothing
     * @return the output file file name
     * @throws ConfigException if "ALL_OUTFILE_NAME" not found in 
     *         configuration file
     */
    public String getAllOutputFileName() throws ConfigException {
        return getConfigString("ALL_OUTFILE_NAME");
    }

    /**
     * Get the filter mode
     * @assumes Nothing
     * @effects Nothing
     * @return the load mode
     * @throws ConfigException if "FILTER_MODE" not found in 
     *         configuration file
     */
    public String getFilterMode() throws ConfigException {
        return getConfigString("FILTER_MODE");
    }
  
}
