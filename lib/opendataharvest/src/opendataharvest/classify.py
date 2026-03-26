import logging
from typing import Dict, List, Optional, Tuple


class ResourceClassifier:
    @staticmethod
    def determine_resource_class_and_type(
        data_dict: Dict,
        resource_class_default: Optional[str] = None,
        resource_type_default: Optional[str] = None,
    ) -> Tuple[List[str], List[str]]:
        """Classify a record into Aardvark resource class and type."""

        def append_if_not_exists(lst: List[str], item: str) -> None:
            if item not in lst:
                lst.append(item)

        logging.debug("Determining resource class and type for data: %s", data_dict)

        gbl_resourceClass_sm = data_dict.get("gbl_resourceClass_sm") or []
        gbl_resourceType_sm = data_dict.get("gbl_resourceType_sm") or []

        logging.debug("Initial resource class: %s", gbl_resourceClass_sm)
        logging.debug("Initial resource type: %s", gbl_resourceType_sm)

        if gbl_resourceClass_sm and gbl_resourceType_sm:
            logging.debug("Resource class and type already determined.")
            return gbl_resourceClass_sm, gbl_resourceType_sm

        dct_title_s = str(data_dict.get("dct_title_s", ""))
        dct_format_s = str(data_dict.get("dct_format_s", ""))
        dct_description_sm = str(data_dict.get("dct_description_sm", ""))
        dct_subject_sm = str(data_dict.get("dct_subject_sm", ""))
        dct_publisher_sm = str(data_dict.get("dct_publisher_sm", ""))
        identifier = str(data_dict.get("id", ""))
        dct_references_s = str(data_dict.get("dct_references_s", ""))
        dct_source_sm = str(data_dict.get("dct_source_sm", ""))

        if (
            ("openindexmaps" in dct_references_s.lower())
            or (identifier == "stanford-ch237ht4777")
            or ("ch237ht4777" in dct_source_sm.lower())
        ):
            logging.debug("OpenIndexMap detected, setting resource class and type.")
            gbl_resourceClass_sm = ["Maps"]
            gbl_resourceType_sm = ["Index maps"]
            if "aerial" in dct_description_sm.lower():
                gbl_resourceClass_sm = ["Imagery"]
            return gbl_resourceClass_sm, gbl_resourceType_sm

        logging.info("Class and Type determination using keywords...")
        logging.debug("id: %s", identifier)
        logging.debug("Title: %s", dct_title_s)
        logging.debug("Format: %s", dct_format_s)
        logging.debug("Description: %s", dct_description_sm)
        logging.debug("Subject: %s", dct_subject_sm)
        logging.debug("Publisher: %s", dct_publisher_sm)
        logging.debug("References: %s", dct_references_s)

        if "aerial photo" in dct_title_s.lower():
            logging.debug("Aerial photogrpahy detected")
            gbl_resourceType_sm = ["Aerial photographs"]
            gbl_resourceClass_sm = ["Imagery"]
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if "sanborn" in dct_publisher_sm.lower():
            logging.debug("Sanborn map detected, setting resource class and type.")
            append_if_not_exists(gbl_resourceClass_sm, "Maps")
            append_if_not_exists(gbl_resourceType_sm, "Fire insurance maps")
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if "topographical map" in dct_title_s.lower():
            logging.debug("topographical map detected, setting resource class and type.")
            append_if_not_exists(gbl_resourceClass_sm, "Maps")
            append_if_not_exists(gbl_resourceType_sm, "Topographic maps")
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if "aeronautical" in dct_title_s.lower():
            logging.debug(
                "Aeronautical charts detected, setting resource class and type."
            )
            append_if_not_exists(gbl_resourceClass_sm, "Maps")
            append_if_not_exists(gbl_resourceType_sm, "Aeronautical charts")
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if "iiif" in dct_references_s.lower():
            logging.debug("IIIF Map detected, setting resource class and type.")
            append_if_not_exists(gbl_resourceClass_sm, "Maps")
            if ("aerial photo" in dct_title_s.lower()) or (
                "aerial photo" in dct_description_sm.lower()
            ):
                logging.debug("IIIF Aerial Photography Detected")
                append_if_not_exists(gbl_resourceType_sm, "Aerial photographs")
            else:
                logging.debug("IIIF Map Detected")
                append_if_not_exists(gbl_resourceType_sm, "Digital maps")
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if dct_format_s in ["GeoTIFF", "TIFF"]:
            if (
                "relief" in dct_description_sm.lower()
                or "map" in dct_description_sm.lower()
                or "maps" in dct_subject_sm.lower()
                or "plan" in dct_title_s.lower()
                or "map" in dct_title_s.lower()
                or "topographic" in dct_title_s.lower()
            ):
                logging.debug(
                    "GeoTIFF or TIFF format with map-related description or subject detected."
                )
                append_if_not_exists(gbl_resourceClass_sm, "Maps")
                append_if_not_exists(gbl_resourceType_sm, "Digital maps")
                return gbl_resourceClass_sm, gbl_resourceType_sm

            if "aerial photo" in dct_title_s.lower():
                logging.debug("Aerial Photogrpahy Detected")
                append_if_not_exists(gbl_resourceType_sm, "Aerial photographs")
                gbl_resourceClass_sm = ["Imagery"]

            logging.debug(
                "GeoTIFF or TIFF format detected, setting resource class to Datasets."
            )
            gbl_resourceClass_sm = ["Datasets"]
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if (
            dct_format_s
            in [
                "Shapefile",
                "ArcGrid",
                "GeoDatabase",
                "Geodatabase",
                "Arc/Info Binary Grid",
            ]
            or "csdgm" in dct_references_s
            or "ArcGIS#" in dct_references_s
        ):
            logging.debug("Setting resource class to Datasets based on format.")
            gbl_resourceClass_sm = ["Datasets"]
            if "aerial photo" in dct_title_s.lower():
                logging.debug("Aerial photogrpahy detected")
                gbl_resourceType_sm = ["Aerial photographs"]
                gbl_resourceClass_sm = ["Imagery"]
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if dct_format_s == "":
            if (
                "relief" in dct_description_sm.lower()
                or "map" in dct_description_sm.lower()
                or "maps" in dct_subject_sm.lower()
            ):
                logging.debug(
                    "Empty format with map-related description or subject detected."
                )
                append_if_not_exists(gbl_resourceClass_sm, "Maps")
                return gbl_resourceClass_sm, gbl_resourceType_sm

            logging.debug("Empty format, setting resource class to Other.")
            gbl_resourceClass_sm = ["Other"]
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if (
            dct_format_s == "ArcGRID"
            or dct_format_s == "IMG"
            or "DEM" in dct_description_sm
            or "DSM" in dct_description_sm
            or "digital elevation model" in dct_description_sm
            or "digital terrain model" in dct_description_sm
            or "digital surface model" in dct_description_sm
            or "arc-second" in dct_description_sm
            or "raster dataset" in dct_description_sm.lower()
        ):
            logging.debug("Elevation or other non-Imagery Raster Detected.")
            append_if_not_exists(gbl_resourceClass_sm, "Datasets")
            append_if_not_exists(gbl_resourceType_sm, "Raster data")
            return gbl_resourceClass_sm, gbl_resourceType_sm

        if (
            "relief" in dct_description_sm.lower()
            or "map" in dct_description_sm.lower()
            or "maps" in dct_subject_sm.lower()
        ):
            logging.debug("Map-related description or subject detected.")
            gbl_resourceClass_sm = ["Maps"]
            return gbl_resourceClass_sm, gbl_resourceType_sm

        logging.debug("Setting default resource class and type.")
        fallback_class = resource_class_default or "Datasets"
        gbl_resourceClass_sm = [fallback_class]

        if resource_type_default:
            gbl_resourceType_sm = [resource_type_default]
        else:
            gbl_resourceType_sm = []

        return gbl_resourceClass_sm, gbl_resourceType_sm
