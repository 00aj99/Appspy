%mex -setup C++;
%qlite3.make

%PLOT FORE + BACK  on the same plot
% + possibility to have diff color for "in between"

%% PARAMETERS
clear;
dbDirectory = 'db';
dbFiles = dir(strcat(dbDirectory, '/db*.db'));
dbFilePaths = {};

type = 'point'; %type = 'bar' or 'point'
logYaxis = 1; %display log scale? (1 = true)
axisLink = 'xy'; %x, y or xy
showParam = 'a'; %a = all, b = back, f = fore
offset=3;
aggregatedTime = 1; %1 = no aggregation

%packagesToProcess = {'com.facebook.katana', 'ch.admin.meteoswiss','com.facebook.orca', 'com.google.android.gm', 'com.whatsapp','com.google.android.gms','com.google.android.googlequicksearchbox','com.google.android.apps.maps','com.kitkatandroid.keyboard','com.zoodles.kidmode','com.google.android.apps.plus'};
packagesToProcess = {'com.google.android.apps.plus'};


%% PROCESSING
databases = ones(1,numel(dbFiles));
for nameIdx = 1 : numel(dbFiles)
    dbFilePaths{nameIdx} = strcat(dbDirectory, '/', dbFiles(nameIdx).name);
    databases(nameIdx) = sqlite3.open(dbFilePaths{nameIdx});
end


close all;
for nameIdx = 1 : numel(dbFilePaths)
    dbPath = dbFilePaths{nameIdx};
    [~,dbName,~] = fileparts(dbPath);
    
    database = databases(nameIdx);
    packagesNames = allPackageName(database);
    
    for packageName = packagesNames
        packageName = packageName{1};
        
        r = strfind(packagesToProcess,packageName);
        if(sum([r{:}]) > 0)
            
            results = sqlite3.execute(database, strcat('SELECT * from table_applications_activity WHERE package_name =''', packageName, ''' AND record_time > (SELECT record_time from table_applications_activity where record_id=1 limit 1) ORDER BY record_time'));
            
            dataX_back = zeros(numel(results),1);
            dataY_back = zeros(numel(results),1);
            
            dataX_fore = zeros(numel(results),1);
            dataY_fore = zeros(numel(results),1);
            
            dataX_ibtw = zeros(numel(results),1);
            dataY_ibtw = zeros(numel(results),1);
            
            
            dataX_down_back = zeros(numel(results),1);
            dataY_down_back = zeros(numel(results),1);
            
            dataX_down_fore = zeros(numel(results),1);
            dataY_down_fore = zeros(numel(results),1);
            
            dataX_down_ibtw = zeros(numel(results),1);
            dataY_down_ibtw = zeros(numel(results),1);
            
            
            lastStatus = ones(1,offset);
            lastRow = cell(1,offset);
            for i = 1:offset
                if(numel(results) > 0)
                    lastRow{i} = results(1);
                end
            end
            
            %         %PREPROCESSING (done one the data are put in array dataY_...
            %         %up/down value < 0 set to 0
            %         idx = find([results.uploaded_data] < 0); a = mat2cell(zeros(1,numel(idx))+5, 1, ones(1,numel(idx))) ;[results(idx).uploaded_data] = a{:};
            
            
            %PROCESS
            for rowIdx = 1:numel(results)
                timestamp = (results(rowIdx).record_time+2*60*60000)/1000;
                time = [1970 1 1 0 0 timestamp];
                t = datetime(time,'InputFormat','dd-MMM-yyyy HH:mm:ss');
                t.Second = 0;
                time = datenum(t);
                
                row = results(rowIdx);
                
                %remove the last foreground activity too old to have impact on
                %background activity
                for lastIdx = 1:offset
                    r = lastRow{lastIdx};
                    if isrow(r) && row.record_time - r.record_time > offset * 60000 + 30000
                        lastRow{lastIdx} = [];
                        lastStatus(lastIdx) = 0;
                    end
                end
                
                
                if(row.was_foreground == 0 && sum(lastStatus) == 0)
                    dataY_back(rowIdx) = results(rowIdx).uploaded_data/1024.0;
                    dataX_back(rowIdx) = time;
                    dataY_down_back(rowIdx) = results(rowIdx).downloaded_data/1024.0;
                    dataX_down_back(rowIdx) = time;
                elseif(row.was_foreground == 1)
                    dataY_fore(rowIdx) = row.uploaded_data/1024.0;
                    dataX_fore(rowIdx) = time;
                    dataY_down_fore(rowIdx) = results(rowIdx).downloaded_data/1024.0;
                    dataX_down_fore(rowIdx) = time;
                elseif(results(rowIdx).uploaded_data > 0)
                    dataY_ibtw(rowIdx) = row.uploaded_data/1024.0;
                    dataX_ibtw(rowIdx) = time;
                    dataY_down_ibtw(rowIdx) = results(rowIdx).downloaded_data/1024.0;
                    dataX_down_ibtw(rowIdx) = time;
                end
                lastStatus(mod(rowIdx,offset)+1) = row.was_foreground;
                lastRow{mod(rowIdx,offset)+1} = row;
            end
            
            %clean: remove where record_time = 0 and where data > 0
            % (keep only the others)
            idxZero = find(dataX_back > 0 & dataY_back > 0);
            dataX_back = dataX_back(idxZero);
            dataY_back = dataY_back(idxZero);
            
            idxZero = find(dataX_fore > 0 & dataY_fore > 0);
            dataX_fore = dataX_fore(idxZero);
            dataY_fore = dataY_fore(idxZero);
            
            idxZero = find(dataX_ibtw > 0 & dataY_ibtw > 0);
            dataX_ibtw = dataX_ibtw(idxZero);
            dataY_ibtw = dataY_ibtw(idxZero);
            
            %clean the same way, but for down
            idxZero = find(dataX_down_back > 0 & dataY_down_back > 0);
            dataX_down_back = dataX_down_back(idxZero);
            dataY_down_back = dataY_down_back(idxZero);
            
            idxZero = find(dataX_down_fore > 0 & dataY_down_fore > 0);
            dataX_down_fore = dataX_down_fore(idxZero);
            dataY_down_fore = dataY_down_fore(idxZero);
            
            idxZero = find(dataX_down_ibtw > 0 & dataY_down_ibtw > 0);
            dataX_down_ibtw = dataX_down_ibtw(idxZero);
            dataY_down_ibtw = dataY_down_ibtw(idxZero);
            
            %aggregate
            
            if(aggregatedTime > 1)
                [ dataX_back, dataY_back, dataX_fore, dataY_fore, dataX_ibtw, dataY_ibtw ] = aggregateData(dataX_back, dataY_back, dataX_fore, dataY_fore, dataX_ibtw, dataY_ibtw, aggregatedTime);
                [ dataX_down_back, dataY_down_back, dataX_down_fore, dataY_down_fore, dataX_down_ibtw, dataY_down_ibtw ] = aggregateData(dataX_down_back, dataY_down_back, dataX_down_fore, dataY_down_fore, dataX_down_ibtw, dataY_down_ibtw, aggregatedTime);
            end
            %% NOW PLOT THE DATA
            
            %find y axis limit, same for all graph to be able to compare
            if(aggregatedTime == 1)
                [minY_upload, maxY_upload, minY_download, maxY_download, minY_global, maxY_global] = findCommonAxisLimits(databases, packageName);
            else
                minY_global = 10^(-1);
                maxY_global = 10^6; %1GB
            end
            
            if(logYaxis ==1)
                minY_global = 10^(-1);
            end
            
            
            if(strcmp(type, 'bar'))
                %% PLOT BAR
                titleFontSize = 34;
                axisLabelFontSize = 28;
                
                resultName = sqlite3.execute(database, strcat('SELECT app_name from table_installed_apps WHERE package_name =''', packageName,''''));
                appname = resultName(1).app_name;
                
                close all;
                if(numel([dataX_back(:)', dataX_fore(:)', dataX_ibtw(:)']) > 0)
                    
                    mkdir('D-processSome')
                    figureNameUpload = strcat('D-processSome/',packageName,'-',dbName,'-aggr',num2str(aggregatedTime), '-bar-upload.pdf');
                    figureNameDownload = strcat('D-processSome/',packageName,'-',dbName,'-aggr',num2str(aggregatedTime), '-bar-download.pdf');
                    fig_upload = plotBar(dataX_back, dataY_back, dataX_fore, dataY_fore, dataX_ibtw, dataY_ibtw, showParam, logYaxis, 'off');
                    title(strcat(appname, {' - upload for candidate '},dbName, {'. Aggregation by '}, num2str(aggregatedTime), {' min.'}),'FontSize',titleFontSize);
                    ylabel('Uploaded data [kB]','FontSize',axisLabelFontSize);
                    set(gca, 'FontSize', axisLabelFontSize);
                    
                    grid on;
                    ylim([minY_global, maxY_global]);
                    saveTightFigure(fig_upload, figureNameUpload);
                    %pause;
                end
                
                if(numel([dataX_down_back(:)', dataX_down_fore(:)', dataX_down_ibtw(:)']) > 0)
                    close all;
                    fig_download = plotBar(dataX_down_back, dataY_down_back, dataX_down_fore, dataY_down_fore, dataX_down_ibtw, dataY_down_ibtw, showParam, logYaxis, 'off');
                    title(strcat(appname, {' - download for candidate '},dbName, {'. Aggregation by '}, num2str(aggregatedTime), {' min.'}),'FontSize',titleFontSize);
                    ylabel('Downloaded data [kB]','FontSize',axisLabelFontSize);
                    set(gca, 'FontSize', axisLabelFontSize);
                    grid on;
                    ylim([minY_global, maxY_global]);
                    saveTightFigure(fig_download, figureNameDownload);
                    %pause;
                end
                
            else
                %% PLOT POINTS
                titleFontSize = 34;
                axisLabelFontSize = 30;
                
                %save figure and remove borders
                close all;
                resultName = sqlite3.execute(database, strcat('SELECT app_name from table_installed_apps WHERE package_name =''', packageName,''''));
                appname = resultName(1).app_name;
                
                if(numel([dataX_back(:)', dataX_fore(:)', dataX_ibtw(:)']) > 0)
                                        mkdir('D-processSome')
                    figureNameUpload = strcat('D-processSome/',packageName,'-',dbName,'-aggr',num2str(aggregatedTime), '-scatter-upload.pdf');
                    figureNameDownload = strcat('D-processSome/',packageName,'-',dbName,'-aggr',num2str(aggregatedTime), '-scatter-download.pdf');
                    
                    fig_upload = plotDataPoint(dataX_back, dataY_back, dataX_fore, dataY_fore, dataX_ibtw, dataY_ibtw, showParam, logYaxis, 'off',axisLabelFontSize);
                    title(strcat(appname, {' - upload for candidate '},dbName, {'. Aggregation by '}, num2str(aggregatedTime), {' min.'}),'FontSize',axisLabelFontSize);
                    ylabel('Uploaded data [kB]','FontSize',axisLabelFontSize);
                    grid on;
                    ylim([minY_global, maxY_global]);
                    axx=gca;
                    axx.XTickLabelRotation = 45;
                    set(gca, 'FontSize', axisLabelFontSize);
                    
                    saveTightFigure(fig_upload, figureNameUpload);
                end
                
                if(numel([dataX_down_back(:)', dataX_down_fore(:)', dataX_down_ibtw(:)']) > 0)
                    close all;
                    fig_download = plotDataPoint(dataX_down_back, dataY_down_back, dataX_down_fore, dataY_down_fore, dataX_down_ibtw, dataY_down_ibtw, showParam, logYaxis, 'off', axisLabelFontSize);
                    title(strcat(appname, {' - download for candidate '},dbName, {'. Aggregation by '}, num2str(aggregatedTime), {' min.'}),'FontSize',titleFontSize);
                    ylabel('Downloaded data [kB]','FontSize',axisLabelFontSize);
                    grid on;
                    ylim([minY_global, maxY_global]);
                    axx=gca;
                    axx.XTickLabelRotation = 45;
                    set(gca, 'FontSize', axisLabelFontSize);
                    saveTightFigure(fig_download, figureNameDownload);
                end
                
            end
            
        end
        
    end
end

%% show stats for all pkg
for pkgIdx = 1:numel(packagesNames)
    packageName = packagesNames{pkgIdx};
    r = strfind(packagesToProcess,packageName);
    if(sum([r{:}]) > 0)
        statsFunc(packageName, offset,dbFilePaths);
    end
end

