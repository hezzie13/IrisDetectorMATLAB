clear;

allData = imageDatastore('trainColours\','IncludeSubfolders',true,'LabelSource','foldernames');
[trainingImages, testingImages] = splitEachLabel(allData, 0.8, 'randomized');

%load in pre-trained CNN, 'mobilenet'
Xception = xception;
analyzeNetwork(Xception);

inputSize = Xception.Layers(1).InputSize;
networkArchitecture = layerGraph(Xception);

featureExtractor = Xception.Layers(168);
classiferOutput = Xception.Layers(170);
numberOfClasses = numel(categories(trainingImages.Labels));

New_Fully_Connected_Layer = fullyConnectedLayer(numberOfClasses, ...
    'Name', 'Connector', ...
    'WeightLearnRateFactor', 10, ...
    'BiasLearnRateFactor', 10);
New_Classification_Layer = classificationLayer('Name', 'Iris Classifier');

networkArchitecture = replaceLayer(networkArchitecture, featureExtractor.Name, New_Fully_Connected_Layer);
networkArchitecture = replaceLayer(networkArchitecture, classiferOutput.Name, New_Classification_Layer);

pixelRange = [-30 30];
scaleRange = [0.9 1.1];

imageResize = imageDataAugmenter('RandXReflection', true, ...
    'RandXTranslation',pixelRange, ...
    'RandYTranslation',pixelRange, ...
    'RandYScale',scaleRange, ...
    'RandXScale', scaleRange);

resizedTrainingData = augmentedImageDatastore(inputSize(1:2),trainingImages, ...
    'DataAugmentation', imageResize);
resizedTestingData = augmentedImageDatastore(inputSize(1:2),testingImages);

sizeMiniBatch = 5;
validationFrequency = floor(numel(resizedTestingData.Files)/sizeMiniBatch);

options = trainingOptions('sgdm', ...
    'InitialLearnRate', 0.001, ...
    'MiniBatchSize', 5, ...
    'MaxEpochs', 6, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData',resizedTestingData, ...
    'ValidationFrequency', validationFrequency, ...
    'Verbose', false, ...
    'Plots', 'training-progress');

retrainedXception = trainNetwork(resizedTrainingData, networkArchitecture, options);