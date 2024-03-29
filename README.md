# Fiji_Macros
ImageJ/Fiji Macros for various image analysis functions. 
## Coloc_Macro.jim

This automates JACoP over a directory with images and corresponding ROI sets and creates a single CSV with colocalization data for each ROI. It does not generate the ROIs.

Look at the [Tutorial PDF](https://github.com/perrochon/Fiji_Macros/raw/5759d88c5bdabb484606c4cd4e969d8b570e4c8a/ImageJ%20and%20JACoP%20Batch%20ROI%20Colocalization%20Analysis%20Macro%20Tutorial.pdf) for details.

After writing this, I found out about the [JACoP BIOP version.](https://c4science.ch/w/bioimaging_and_optics_platform_biop/image-processing/imagej_tools/jacop_b/) That runs JACoP over all ROIs and comes with a script to do it over a directory. You may still want to apply some of this Macro to collect and process logs and results.

Colocalization analysis is a technique used to determine the extent to which two different molecules or structures are localized in the same region of a cell. ImageJ is a popular image processing software that can be used to perform colocalization analysis. JACoP is a plugin for ImageJ that provides a variety of tools for colocalization analysis.

Often, only regions of interest (ROI, in particular only cells) are used for the analysis, and doing the analysis for many ROI in many images is turning into a long list of manual steps, perfect for automation.

It is rumored that this ROI based analysis is so much work that some researchers use Colocalization Analysis on the whole picture. While that may be acceptable in some cases, it may not be in others.

This tutorial and macro focuses on how to get that automation done, with some consideration of the scientific environment and keeping a detailed log of what actually has been done so results can be reproduced more easily. 

This tutorial will help with neither the biology nor the math. The macro will not generate the ROIs. Automating ROIs is outside the scope of this tutorial.  The tutorial will not teach basic FIJI/ImageJ manual tasks. 

The tutorial will also not teach any coding skills, and it's very likely you will need to modify the macro. The key elements are there, but this is not a supported and finished product. The macro and tutorial will get you most of the way, though.


## Measure_Macro.jim
This automates Analyze-Measure (Ctrl-M) across a directory with images and corresponding ROI sets and creates a single CSV with the area (and also mean gray value for one channel) for each ROI. It does not generate the ROIs.

It also generates a lot of statistical data automatically. You can use that directly, or compare it to whatever results your data processing softare generates. Ideally, it should be the same results e.g. for StdDev.


---
If you feel this is worth of an acknowledgement in your derived work, point to this github project.
