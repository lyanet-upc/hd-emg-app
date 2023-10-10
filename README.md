This application is designed to analyze HD-sEMG data from twelve healthy male participants performing isometric contractions. The data is part of the collection in which this application is hosted.

### How to Use the Matlab Application
1. **Download Data**: Retrieve the dataset from fig-share using the following DOIs:
    - Part 1/3: `10.6084/m9.figshare.11860572`
    - Part 2/3: `10.6084/m9.figshare.11860851`
    - Part 3/3: `10.6084/m9.figshare.11860959`
  
2. **Database Details**: The downloaded dataset includes HD-sEMG signals from healthy participants engaged in four isometric tasks: elbow flexion/extension and forearm pronation/supination. Data is recorded at 10%, 30%, and 50% of maximum voluntary contraction levels, with each recording lasting 10 seconds. The dataset includes twelve folders (one for each subject) along with `forearm.txt`, `nchannels.txt`, and `ReferencePoints.txt` files, which should be in the root directory of the database folder

3. **Initialize App**: Open `hd_emg_app.m` to launch the user interface. Use the "Load Data Base" button to upload the dataset.

5. **Analysis**: Once the data is loaded, you can select the subject, task, effort level, and window size for analysis. Various types of HD-EMG maps (contour, surface, and surface+contour) can be viewed. Navigate through the signal using the forward and backward buttons located at the bottom right corner. Right-click on specific channels (black dots) in the HD-EMG maps to view the temporal EMG signal.

6. **Support**: Should you encounter any issues, please reach out to us via email at leidy.yanet.serna@upc.edu.

Feel free to contact us for further assistance.
