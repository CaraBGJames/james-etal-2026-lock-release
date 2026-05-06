"""
pickling_csvs.py: converts all CSV files in a given folder to pickled NumPy array and saves them in a named folder.
"""

import numpy as np
import glob
import pickle
import os


def pickle_csvs_in_folder(csv_folder, pickle_folder, string_contains=None):
    """
    Converts all CSV files in a folder to pickled NumPy arrays and saves them in another folder.

    Args:
        csv_folder (str): Path to the folder containing CSV files.
        pickle_folder (str): Path to the folder where you want the pickles saved.
        string_contains (str, optional): Only files containing this substring in the name will be processed.

    Returns:
        None
    """
    os.makedirs(pickle_folder, exist_ok=True)  # Make sure the output folder exists

    for file_path in glob.glob(os.path.join(csv_folder, "*.csv")):
        if string_contains is not None and string_contains not in file_path:
            continue

        name = os.path.splitext(os.path.basename(file_path))[0]
        data = np.genfromtxt(file_path, delimiter=",")
        pickle_path = os.path.join(pickle_folder, name + ".pickle")

        with open(pickle_path, "wb") as file:
            pickle.dump(data, file)

    print("Alllll pickled!")


pickle_csvs_in_folder(
    csv_folder="FOLDER WHERE CSV OF DATA ARE EXPORTED TO FROM MATLAB",
    pickle_folder="FOLDER WHERE PICKLED FILES WILL BE SAVED",
    string_contains="EXPERIMENT NAME OR OTHER STRING TO FILTER FILES",
)
