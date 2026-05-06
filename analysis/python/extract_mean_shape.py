"""
extract_mean_shape.py: stacks current profiles from .npy files of height and extracts the mean shape, saves back to npy if chosen to.
"""

import numpy as np

folder = "../../data/datafiles"


def stacked_current_profile(height, front, min_profile_length=0.6):

    # get x_pixel real length by dividing max length by number of pixels in height 2nd dimension
    length_m = np.max(front)
    length_pix = np.shape(height)[1]
    pixel_m = length_m / length_pix

    # find time (index) where front at 60cm (test a few)
    t_idx = np.argmax(front > min_profile_length)  # first >60cm value in front

    # from this time onwards, take each timestep and
    height_cropped = height[t_idx:, :]  # get rid of short profiles at early times
    height_stack = np.full(
        np.shape(height_cropped), np.nan
    )  # empty array to save in (full of nans)

    # presave the non dimensionalised x direction
    xcenters = (
        np.arange(0, np.shape(height_stack)[1]) * pixel_m
    )  # non dimensionalised distance / lock length

    # 1. work out where the front position is from fist 0 value of height
    for t_step in range(np.shape(height_cropped)[0]):
        heights_at_t = height_cropped[t_step, :]
        front_pos_pix = np.argmin(heights_at_t != 0)

        # 2. take the portion up until this point (i.e. the whole plume), flip it around, save in first x values of a new array
        flipped_height = heights_at_t[:front_pos_pix][::-1]
        height_stack[t_step, :front_pos_pix] = flipped_height

    # Mean
    av_shape = np.nanmean(height_stack, axis=0)

    # Standard deviation ignoring NaNs
    av_shape_std = np.nanstd(height_stack, axis=0)

    return (
        xcenters,
        av_shape,
        av_shape_std,
        height_stack,
    )


if __name__ == "__main__":

    import matplotlib.pyplot as plt
    import os
    import pandas as pd

    save = True
    plot = True

    # ###### load data
    metadata = pd.read_csv("metadata.csv")
    folder = "../../data/datafiles"

    for _, row in metadata.iterrows():
        if "SN7_redo" in row.file_name:
            exp_name = row.file_name
            print(exp_name)
            filename = folder + "/" + exp_name + ".npy"
            data = np.load(filename, allow_pickle=True).item()
            front = np.abs(data["front_m"])
            height = np.abs(data["height_m"])

            xcenters, av_shape, av_shape_std, height_stack = stacked_current_profile(
                height, front, min_profile_length=0.6
            )

            # ###### add these and rewrite the datafile
            # Add/update new keys
            data["xcenters"] = xcenters
            data["av_shape"] = av_shape
            data["av_shape_std"] = av_shape_std
            data["height_stack"] = height_stack

            # Save back to the same file
            if save:
                np.save(filename, data)
                print(f"Updated: {os.path.basename(exp_name)}")

            if plot:
                fig, ax = plt.subplots(figsize=(10, 3))

                ax.plot(xcenters / 0.28, height_stack.T / 0.25, c="r", alpha=0.01)
                ax.plot(xcenters / 0.28, av_shape / 0.25, "k")
                ax.fill_between(
                    xcenters / 0.28,
                    (av_shape - av_shape_std) / 0.25,
                    (av_shape + av_shape_std) / 0.25,
                    color="k",
                    alpha=0.2,
                )
                ax.set_ylim([0, 1])
                ax.set_xlabel("$x/L_0$ [-]")
                ax.set_ylabel("$h/H_0$ [-]")
                ax.tick_params(
                    direction="in",
                    top=True,
                    right=True,
                )
                plt.show()
