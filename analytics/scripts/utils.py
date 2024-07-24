#%% METADATA

# User: AndreEscobar
# Date: 04/07/2024
# Hour: 01:18
# Role: Data Scientist
# Project: Preparacion de repositorio leads red salud

#%% DESTACADAS

# ----------------- CARGA DE ARCHIVOS ------------------
def GET_LAST_FILE(folder, search_text):
     
     import os

     if folder[-1] != '/':
          folder = folder + '/'
    
     files = sorted([f for f in os.listdir(folder) if search_text in f])
     file = folder + files[-1]

     return file

def READ_JSON(file, method='dict'):
    
    import json

    if method == 'dict':
         with open(file) as f:
              output = json.load(f)
    elif method == 'dataframe':
         pass
    
    return output

def ADD_ROWID(dataframe, colname = 'uniqueid'):

    import numpy as np
    import pandas as pd

    dataframe = dataframe.copy()
    
    dataframe[colname] = np.arange(len(dataframe))
    dataframe[colname] = dataframe[colname].astype(str)
    
    lastid = dataframe[colname].values[-1]
    dataframe[colname] = 'id_' +dataframe[colname].apply(lambda x: x.zfill(len(lastid)))
    dataframe.set_index(colname, inplace=True)

    return dataframe


# ----------------- ALMACENAR ARCHIVOS -----------------
def GET_NOW_STRING():
     
    from datetime import date
    from datetime import datetime

    today = date.today()
    today = today.strftime('%Y%m%d')

    now = datetime.now()
    now = now.strftime('%H%M')

    string = '_' + today + '_' + now

    return string

def SAVE_CPICKLE(obj, path):
       
        import compress_pickle as cpickle

        ext = path.split('.')[-1]
        if ext != 'lzma':
             print('\nERROR: Use .lzma path...')
        else:
             with open(path, 'wb') as file:
                   cpickle.dump(obj, file, compression='lzma')

def SAVE_EXCEL_MULTISHEET(container, path, engine='openpyxl', ind=False):
        
        import numpy as np
        import pandas as pd

        ext = path.split('.')[-1]
        if ext != 'xlsx':
             print('\nERROR: Use .xlsx path...')

        else:

            if type(container) == dict:
                 
                keys  = list(container.keys())
                
                with pd.ExcelWriter(path) as writer:
                    print('Writing to {}'.format(path))
                    for k in keys:
                        print('     ...',k,'sheet')
                        container[k].to_excel(writer, sheet_name=k, index=ind, engine=engine)
                    print('     ... done!')
            
            elif type(container) == list:
                 
                 with pd.ExcelWriter(path) as writer:
                    print('Writing to {}'.format(path))
                    for i in np.arange(len(container)):
                        k = 'sheet' + str(i)
                        print('     ...', k)
                        container[i].to_excel(writer, sheet_name=k, index=ind, engine=engine)
                    print('     ... done!')

# ----------------- INTERACCION SQL -----------------
def CONNECT_SQL(server='None', database=None, schema=None, over = 'session', help=False):
        
    if help:
          print('server (str): ["kpi","des","des02"] ...')
          print('over (str): ["connection", "session"] ...')

    else: 
          import sqlalchemy as sql
          from sqlalchemy.orm import sessionmaker

          # Crear el string para configurar la conexion

          cstring = "mssql+pyodbc:///?odbc_connect=Driver={ODBC Driver 17 for SQL Server};"

          if server=='kpi':
                    server_string = 'SRV-WIN16SQLKPI'
          
          elif server == 'des':
                    server_string = 'winsqldes'

          elif server == 'des02':
                    server_string = 'winsqldes02'

          else:
                    return 'ERROR: Indica un servidor'
          
          cstring = cstring + "Server=" + server_string +";Trusted_Connection=yes;"

          if database != None:
                    cstring = cstring + "Database=" + database + ";"

          if schema != None:
                    cstring = cstring + "Schema=" + schema + ";"

          # Usar el string para conectarse al servidor

          engine = sql.create_engine(cstring)
          
          # Definir el intermediario de datos
     
          if over == 'connection': 
               output = engine.connect()
          
          elif over == 'session':
               output = sessionmaker(bind=engine)()

          return output

def EXECUTE_SQL_QUERY(path, over_obj, over='session', help=False):
        
     if over == 'connection':
     
          import chardet
          import pandas as pd
          import sqlalchemy as sql
          
          with open(path, 'rb') as file:
               query = file.read()
               query = query.decode(chardet.detect(query)['encoding'],'ignore')
               df = pd.read_sql(sql.text(query), over_obj, index_col=None)
     
     elif over == 'session':

          import pandas as pd
          import sqlalchemy as sql

          with open(path, 'r') as file:
               query = file.read()
               query = "SET NOCOUNT ON ; \n" + query + "; SET NOCOUNT OFF"
               result = over_obj.execute(sql.text(query)).fetchall()
               df = pd.DataFrame(result)

     over_obj.close()

     return df


#%% POCO COMUNES

# ----------------- CARGA DE ARCHIVOS ------------------
def DETERMINE_CSV_DELIMITER(file, maxfactor=5,factor=1, verbose=False):
     # Esta funcion prueba cual es el delimitador de un archivo csv
     # aplica la funcion de forma iterativa hasta encontrarlo o levantar un error

    import csv

    try:
        if verbose: print('factor:', factor, 'samples:', (2 ** (5 + factor)))
        with open(file) as f:
            lector = csv.Sniffer()
            review = lector.sniff(f.read(2 ** (8 + factor)))
            delimiter = review.delimiter
    except:
        if factor <= maxfactor:
            delimiter = DETERMINE_CSV_DELIMITER(file, maxfactor=maxfactor, factor=factor+1)
        else:
            delimiter = 'error'
    return delimiter

# ----------------- APROXIMACION DECIMALES ------------------
def R0(x):
     import numpy as np
     y = np.round(x, 0)
     return y

def R2(x):
     import numpy as np
     y = np.round(x, 2)
     return y

def R4(x):
     import numpy as np
     y = np.round(x, 4)
     return y

# ----------------- CALCULO DE MODA -------------------------
def GET_MODE(vector=False, dataframe=False, column=False):
     
     import numpy as np
     import pandas as pd

     if  type(dataframe) == bool:
          
          if type(vector) == bool:
              y = 'Error'
              print('Error: Insert data as vector or dataframe') 
          
          else:
              y = pd.Series(vector).value_counts().index[0]
     
     else:
          
          dft = dataframe.copy()

          if column == False:
               y = 'Error'
               print('Error: Define a column to calculate')

          else:
               vector = dft[column]
               y = pd.Series(vector).value_counts().index[0]

     return y

def GET_DF_MODE(dataframe, use_tqdm = False):
     
     import numpy as np
     import pandas as pd

     dft = dataframe.copy()

     columns = dft.columns
     
     dicto = {}

     if use_tqdm:
          
          import tqdm
          
          for i in tqdm.tqdm(np.arange(len(columns)), desc='Getting statistical mode', ncols=100):
               c = columns[i]
               y = dft[c].value_counts().index[0]
               dicto[c] = y
     else:
          
          for c in columns:
               print('getting stadistical mode:', c, '...')
               y = dft[c].value_counts().index[0]
               dicto[c] = y
          print('   ... done!')

     y = pd.Series(dicto).to_frame().reset_index()
     y.columns = ['Campo','Moda']
     
     return y


#%% DEPRECADAS

def DF_VALUE_COUNTS(dataframe, column):
     
     import numpy as np
     import pandas as pd
     
     dft = dataframe.copy()

     values = pd.concat([dft[column].value_counts(), dft[column].value_counts(normalize=True)], axis=1)
     values.reset_index(inplace=True, drop=False)
     values.columns = ['Campo','Frecuencia','Relativo']
     
     values.Relativo = np.round(values.Relativo, 2)
     
     return values

def ESTIMATE_MISSING_VALUES(dataframe, depvar, indvars=[], model='lreg', method='reg', normetric=False, seed=16, vsize=0.1, verbose=True):
     
     import numpy as np
     import pandas as pd
     
     dft = dataframe.copy()

     models = ['lreg', 'dtree','forest','svm']
     methods = ['regress','clasif']

     if method == 'regress':
          
          from sklearn.metrics import mean_squared_error
          metric_func = mean_squared_error

          if model == 'lreg':
               from sklearn.linear_model import LinearRegression
               algorithm = LinearRegression()
          elif model == 'dtree':
               from sklearn.tree import DecisionTreeRegressor
               algorithm = DecisionTreeRegressor(random_state=seed)
          elif model == 'forest':
               from sklearn.ensemble import RandomForestRegressor
               algorithm = RandomForestRegressor(random_state=seed)
          elif model == 'svm':
               from sklearn.svm import SVR
               algorithm = SVR()
          else:
               print('Choose a valid model:', models)
               return None
          
     elif method == 'clasif':
          
          from sklearn.metrics import roc_auc_score
          metric_func = roc_auc_score
          
          if model == 'lreg':
               from sklearn.linear_model import LogisticRegression
               algorithm = LogisticRegression()

          elif model == 'dtree':
               from sklearn.tree import DecisionTreeClassifier
               algorithm = DecisionTreeClassifier(random_state=seed)

          elif model == 'forest':
               from sklearn.ensemble import RandomForestClassifier
               algorithm = RandomForestClassifier(random_state=seed)
          elif model == 'svm':
               from sklearn.svm import SVC
               algorithm = SVC()
          else:
               print('Choose a valid model:', models)
               return None
     
     else:
          print('Choose a valid method:', methods)
          return None
     
     if type(indvars) == str:
          indvars = [indvars]
     
     for v in indvars:
          dft = dft.loc[dft[v].notna(), :]
    
     dft = dft.loc[:, [depvar] + indvars]

     ytrval = dft.loc[dft[depvar].notna(), depvar]
     xtrval = dft.loc[dft[depvar].notna(), indvars]

     if type(xtrval) == pd.Series:
          xtrval = xtrval.to_frame()
     
     from sklearn.model_selection import train_test_split
     xtr, xval, ytr, yval = train_test_split(xtrval, ytrval, test_size=vsize, random_state=seed, shuffle=True) 
     
     yts = dft.loc[dft[depvar].isna(), depvar]
     xts = dft.loc[dft[depvar].isna(), indvars]

     if type(xts) == pd.Series:
          xts = xts.to_frame()

     from sklearn.preprocessing import StandardScaler
     zscaler = StandardScaler()

     ztr = pd.DataFrame(zscaler.fit_transform(xtr), index=xtr.index, columns=xtr.columns)
     zval = pd.DataFrame(zscaler.transform(xval), index=xval.index, columns=xval.columns)
     zts = pd.DataFrame(zscaler.transform(xts), index=xts.index, columns=xts.columns)

     ### AGREGAR AQUI EL BALANCEO DE CLASES ###

     algorithm.fit(ztr, ytr)

     ptr = algorithm.predict(ztr)
     pval = algorithm.predict(zval)
     pts = algorithm.predict(zts)
     
     if method == 'regress':
          
          metric = np.sqrt(metric_func(yval, pval))
          
          if normetric == True:
               mn = np.abs(np.mean(yval))
               
               if mn == 0:
                    print('Error: Dividing by zero')
                    return None
               else:
                    metric = metric / mn

               if verbose:
                    print('Rmse normalizado obtenido:', metric)
          
          else:
               if verbose:
                    print('Rmse obtenido:', metric)

          output = pd.DataFrame(pts, index=yts.index, columns=[depvar])
          
     elif method == 'clasif':
          
          proba_ts = algorithm.predict_proba(zts)
          proba_val = algorithm.predict_proba(zval)

          metric = np.round(metric_func(yval, proba_val), 4)
          if verbose:
            print('AUC obtenido:', metric)
          
          output = pd.concat([pts, proba_ts], axis=1)
          output.columns = ['pred', 'proba']

     return output, metric, algorithm

def CHECK_MISSING_PERCENT(dataframe):
     
     import numpy as np
     import pandas as pd
     
     dft = dataframe.copy()
     y = (dft.isna().sum(axis=1) > 0).sum() / dft.shape[0]

     return y

def FIX_MISSINGVALUES(dataframe, fix_dict, use_tqdm=False):
     
     import numpy as np
     import pandas as pd
     
     dft = dataframe.copy()

     keys = list(fix_dict.keys())
     
     if use_tqdm:
          
          import tqdm

          for i in tqdm.tqdm(np.arange(len(keys)), desc='Fixing missing values', ncols=100):
               key = keys[i]
               dft[key] = dft[key].fillna(fix_dict[key])

     else:
          print('Fixing missing values using fix arguments ...')

          for key in keys:               
               dft[key] = dft[key].fillna(fix_dict[key])
          
          print('   ... done!')

     return dft 

def CHECK_MISSINGVALUES(dataframe):
     
     import numpy as np
     import pandas as pd

     dft = dataframe.copy()
     dft.reset_index(inplace=True, drop=True)
     
     missing = dft.isna().sum(axis=0).sort_values(ascending=False).to_frame().reset_index()
     missing.columns = ['Campo', 'ValoresPerdidos']
     missing['Porcentaje'] = missing.ValoresPerdidos / dft.shape[0]
     missing = missing.loc[missing.ValoresPerdidos > 0, :]
     
     return missing

def CHECK_DUPLICATED(dataframe):

     import numpy as np
     import pandas as pd
     
     dft = dataframe.copy()

     index0 = False
     index_nd_nk = False
     index_d_nk = False
     index_nd_k = False
     index_d_k = False
     md = False

     dft.reset_index(inplace=True, drop=True)

     # filas totales
     index0 = dft.index.tolist()
     
     # filas no duplicadas sin keep
     index_nd_nk = dft.drop_duplicates(keep=False).index.tolist()
     
     # filas duplicadas sin keep
     index_d_nk = list(set(index0) - set(index_nd_nk))

     # filas no duplicadas con keep
     index_nd_k = dft.drop_duplicates(keep='first').index.tolist()

     # filas duplicadas con keep
     index_d_k = list(set(index0) - set(index_nd_k))

     # margen de duplicacion
     if len(index_d_k) == 0:
          md = -1
     else:     
          md = np.round(len(index_d_nk) / len(index_d_k), 2)

     # filas duplicadas con keep
     dicto = {'totales': len(index0), 'no duplicados sin keep': len(index_nd_nk), 'duplicados sin keep': len(index_d_nk),
              'no duplicados con keep': len(index_nd_k), 'duplicados con keep': len(index_d_k), 'margen de duplicacion': md}

     return dicto

def READ_TABLE_FOLDER(table_dir, read_data=False, help=False):

    if help:
         
         print('table_dir (str): tables folder + table name ...')
         print('read_data (bool): load data.csv in table_dir ...')

    else:
         
        import pandas as pd

        # CARGAR ARCHIVO PATHS
        with open(table_dir + 'paths.txt') as file:
            paths = file.readlines()

        paths = [x.strip().split(';') for x in paths]

        paths_dict = {}
        for path in paths:
            paths_dict[path[0]] = path[1]

        # CARGAR ARCHIVO CAMPOS
        with open(table_dir + 'campos.txt') as file:
            campos = file.readlines()

        campos = [x.strip().split(';') for x in campos]

        campos_dict = {}
        for camp in campos:
            campos_dict[camp[0]] = {'sqltype': camp[1], 'pytype': camp[2]}
        
        # CARGAR ARCHIVO CONFIG
        with open('tables/configs.txt') as file:
            configs = file.readlines()
            configs = [x.strip().split(';') for x in configs]

        configs_dict = {}
        for config in configs:
            configs_dict[config[0]] = config[1]

        # CARGAR DATOS
        if read_data:
            data = pd.read_csv(table_dir + 'data.csv', sep=';')

        else:
            data = None

        return {'paths': paths_dict, 'campos': campos_dict, 'configs': configs_dict, 'data': data, 'dtypes':None}

def PREPARE_SQL_DATASET(table_dict, mode, help=False):
     
    if help:
         
         print('table_dict (dict): output from READ_TABLE_FOLDER with valid DataFrame (Same columns as table_dict["campos"]) ...')
         print('mode (str): ["create","update"] ...')
    
    else:

        import numpy as np
        import pandas as pd
        import sqlalchemy as sql
        from datetime import datetime

        cols = list(table_dict['data'].columns)

        # INGESTAR DATOS A DATAFRAME
        
        moddate = datetime.now()
        moddate = datetime(year=moddate.year, month=moddate.month, day=moddate.day, hour=moddate.hour, minute=moddate.minute, second=moddate.second, microsecond=0)

        if 'UsuarioModificacion' in cols:
            table_dict['data'].UsuarioModificacion = table_dict['configs']['USER']
        
        if 'FechaModificacion' in cols:
             table_dict['data'].FechaModificacion = moddate

        if 'FechaCreacion' in cols:
            if mode == 'create':
                table_dict['data'].FechaCreacion = moddate
            elif mode =='update':
                table_dict['data'].drop('FechaCreacion', axis=1, inplace=True)

        # CONFIGRAR CAMPOS DEL DATAFRAME
        for campo in list(table_dict['campos'].keys()):

            tipo_py = table_dict['campos'][campo]['pytype']
            tipo_sql = table_dict['campos'][campo]['sqltype']

            # print(campo, ': ', tipo_sql, 'to', tipo_py)

            table_dtypes = {}

            if tipo_sql == 'INT':

                table_dtypes[campo] = sql.types.INTEGER

                if not 'int' in str(table_dict['data'][campo].dtype):
                    table_dict['data'][campo] = np.round(table_dict['data'][campo].values, 0)
                    table_dict['data'][campo] = table_dict['data'][campo].astype(int)

            elif tipo_sql == 'DECIMAL':

                precision = tipo_sql.split('DECIMAL(')[1].split(')')[0]
        
                digits = int(precision.split(',')[0])
                decimals = int(precision.split(',')[1])

                table_dtypes[campo] = sql.types.DECIMAL(digits, decimals)

                if not 'float' in str(table_dict['data'][campo].dtype):
                    table_dict['data'][campo] = table_dict['data'][campo].astype(float)
                    table_dict['data'][campo] = np.round(table_dict['data'][campo].values, decimals)

            elif tipo_sql == 'DATETIME':

                table_dtypes[campo] = sql.types.DATETIME

                if not 'datetime' in str(table_dict['data'][campo].dtype):
                    table_dict['data'][campo] = pd.to_datetime(table_dict['data'][campo])

            elif tipo_sql.split('(')[0] == 'VARCHAR':
                length = int(tipo_sql.split('(')[1].split(')')[0])

                table_dtypes[campo] = sql.types.VARCHAR(length)

                table_dict['data'][campo] = table_dict['data'][campo].astype(str)
                table_dict['data'][campo] = table_dict['data'][campo].str[:length]

        table_dict['dtypes'] = table_dtypes

        return table_dict

def SEND_SQL_DATA(dataframe, connection, method, table_path, table_dtypes, test=False, help=False, chunks=0):

        if help:
             
             print('table_path (list): [database, scheme, tablename]')
             print('dataframe (df): output from PREPARE_SQL_DATASET or a valid pandas df ...')
             print('connection (connection): output from CONNECT_SQL ...')
             print('method (str): ["append","replace","fail"] ...')
             print('test (bool): try a testquery ...')
            
        else:

            import pandas as pd
            import sqlalchemy as sql
            
            path = '[' + table_path[0] + '].[' + table_path[1] + '].[' + table_path[2] + ']'

            if chunks == 0:
                dataframe.to_sql(table_path[-1], connection, schema = table_path[0] + '.' + table_path[1], if_exists=method, index=False, dtype=table_dtypes)

            else:
                dataframe.to_sql(table_path[-1], connection, schema = table_path[0] + '.' + table_path[1], if_exists=method, index=False, dtype=table_dtypes, chunksize=chunks) 

            if test:
                 query = "SELECT TOP 5 * \nFROM " + path
                 testdata = pd.read_sql(query, connection)
                 print(testdata)

def corr_magnitud(values):

    output = []

    for i in range(len(values)):

        value = abs(values[i])
        
        if value < 0.2:
            mg = '(-----)'
        elif value < 0.4:
            mg = '(*----)'
        elif value < 0.6:
            mg = '(**---)'
        elif value < 0.8:
            mg = '(***--)'
        elif value < 1:
            mg = '(****-)'
        else:
            mg = '(*****)'

        output.append(mg)

    return output

def ANALIZE_CORR(dataframe, target = 'magnitud', return_input = False):

     import pandas as pd
     import numpy as np
     
     if dataframe.shape[0] != dataframe.shape[1]:
          
          print('Error: La matriz de correlacion no es cuadrada, inserte .corr()')
          return None

     else:

          input_dataframe = dataframe.copy()
          for i in range(input_dataframe.shape[0]-1):
               input_dataframe.iloc[0:i, i] = np.nan
               input_dataframe.iloc[0:-1, -1] = np.nan

          
          if target in 'magnitud':

               # calcular la clasificacion de magnitud

               output_dataframe = input_dataframe.copy()
               for c in dataframe.columns:
                    output_dataframe[c] = output_dataframe[c].astype(str)
                    output_dataframe.loc[input_dataframe[c].isna(), c] = ''
                    output_dataframe.loc[input_dataframe[c].notna(), c] = corr_magnitud(input_dataframe.loc[:, c].dropna().values)

               # obtener mapa de magnitudes
               
               items = [('verystrong', '(****-)'), ('strong', '(***--)'), ('moderate', '(**---)'), ('weak', '(*----)'), ('veryweak', '(-----)')]
               output_dict = {'verystrong': [], 'strong': [], 'moderate': [], 'weak': [], 'veryweak': []}

               for c in output_dataframe.columns:

                    serie = output_dataframe.loc[output_dataframe[c] != '', c][1:]
                    classes = serie.unique().tolist()
               
                    for item in items:

                         if item[1] in classes:
                              classed = serie.loc[serie == item[1]]
                              output_dict[item[0]] = output_dict[item[0]] + [tuple(sorted((c, x))) for x in classed.index.tolist()]

               for k in output_dict.keys():
                    output_dict[k] = sorted(output_dict[k])

               # obtener promedio correlaciones

               output_serie = {}

               for c in dataframe.columns:
                    serie = dataframe.loc[:, c]
                    output_serie[c] = serie.loc[serie.index != c].abs().mean()

               output_serie = pd.Series(output_serie).sort_values(ascending = False)
          
          if return_input:
               return output_dataframe, output_dict, output_serie, input_dataframe
          else:
               return output_dataframe, output_dict, output_serie

def MATRIZ_CASOS(df_vectores):
      
    import pandas as pd
    import numpy as np

    # FUNCION QUE BUSCA SI UNA SERIE DE TIEMPO ES UN CASO RARO O NO
    def BUSCAR_CASO(v):
        suma_abs = sum(v!=0) # SI ES CERO, ENTONCES NO TIENE DATOS
        divc = sum(v==-1)/suma_abs # SI ES 1, ENTONCES SOLO TIENE VALORES CANCELADOS

        frame = v.to_frame()
        frame.columns = ['VECTOR']
        frame['ABS_CUMSUM'] = v.abs().cumsum()
        frame['ZEROS'] = frame.ABS_CUMSUM.apply(lambda x: 1 if x == 0 else 0)

        new_vector = frame[frame.ZEROS == 0].VECTOR
        new_vector

        first = new_vector[0] # SI ES -1, ENTONCES COMIENZA CANCELADA
        postcero = sum(new_vector==0) # SI NO ES CERO, ENTONCES TIENE MESES NO REGISTRADOS

        if suma_abs == 0:
            c1 = 1 # SIN DATOS
        else:
            c1 = 0
            
        if divc == 1:
            c2 = 1 # SOLO CANCELADOS
        else:
            c2 = 0

        if first == -1:
            c3 = 1 # COMIENZA CANCELADA
        else:
            c3 = 0

        if postcero != 0:
            c4 = 1 # TIENE MESES NO REGISTRADOS
        else:
            c4 = 0

        # COMPRUEBO SI CUMPLE ALGUNA CONDICION DE CASO EXTRAÑO
        cs = c1 + c2 + c3 + c4
        if cs > 0:
            c = 1
        else:
            c = 0
        
        # GUARDO UNA MATRIZ DE DUMMIES CON LA CONDICION DE CASO ENCONTRADA
        dicto = {'CASO':c, 'SIN_DATOS':c1,'SOLO_CANCELADOS':c2,
                'COMIENZA_CANCELADA':c3,'MESES_NO_REGISTRADOS':c4}

        return dicto

    # PARA CADA POLIZA, UTILIZO LA FUNCION PARA BUSCAR SI ES UN CASO RARO O NO
    polizas = list(df_vectores.index)

    casos_dict = {}
    for p in polizas:
        casos_dict[p] = BUSCAR_CASO(df_vectores.loc[p,:]) # Serie Tiempo de una Poliza

    # EXPORTO UN DATAFRAMES CON LOS CASOS RAROS ENCONTRADOS Y SU RESPECTIVA SERIE DE TIEMPO
    casos_df = pd.DataFrame(casos_dict).T
    casos_df = pd.concat([casos_df,df_vectores], axis=1)
    casos_df = casos_df[casos_df.CASO == 1]

    # ORDENO EL DATAFRAME
    casos_df.reset_index(inplace=True, drop=False)
    cols = list(casos_df.columns)
    cols[0] = 'POLIZA'
    casos_df.columns = cols

    return casos_df

def GET_VECTORES_PARCIALES(df_vectores):
    
    import pandas as pd
    import numpy as np

    # FUNCION QUE ELIMINA LOS PERIODOS ANTERIORES A QUE ENTRARA LA POLIZA
    def VECTOR_PARCIAL(v):
        frame = v.to_frame()
        frame.columns = ['VECTOR']
        frame['ABS_CUMSUM'] = v.abs().cumsum()
        frame['ZEROS'] = frame.ABS_CUMSUM.apply(lambda x: 1 if x == 0 else 0)

        vp = frame[frame.ZEROS == 0].VECTOR

        return vp
    
    polizas = list(df_vectores.index)

    vectores = {}
    for p in polizas:
        vectores[p] = VECTOR_PARCIAL(df_vectores.loc[p,:]) # Serie Tiempo de una Poliza

    return vectores

class LoopStepClock:

    def __init__(self, nt, nflags=10):
          
        import numpy
        import time

        self.time = time
        self.np = numpy

        self.nt = nt
        self.nflags = nflags

        self.stime = self.time.time()
        self.ctime = None
        
        if nflags == 10:
            self.flags = {'10':False, '20':False, '30':False, '40':False, '50':False, 
                          '60':False, '70':False, '80':False, '90':False, '100':False}
        elif nflags == 4:
            self.flags = {'25':False, '50':False, '75':False, '100':False}

        elif nflags == 2:
            self.flags = {'50':False, '100':False}
        
        elif nflags == 20:
             self.flags = {'5':False, '10':False, '15':False, '20':False, '25':False,
                           '30':False, '35':False, '40':False, '45':False, '50':False,
                           '55':False, '60':False, '65':False, '70':False, '75':False,
                           '80':False, '85':False, '90':False, '95':False, '100':False}
                           
        else:
            return 'ERROR: nflags must be 2, 4 or 10'
            
    def step(self, ni):
        
        float_p = ni / self.nt
        int_p = int(self.np.floor(float_p*100))
        str_p = str(int_p)

        cuts = list(self.flags.keys())

        if str_p in cuts:

            if self.flags[str_p] == False:

                self.ctime = self.time.time()
                sttr = self.np.round(self.ctime - self.stime, 0)

                stfa = int(self.np.round((sttr / float_p) - sttr, 0))
                mtfa = self.np.round(stfa / 60, 2)
                htfa = self.np.round(mtfa / 60, 2)
                
                self.flags[str_p] = True

                return [str_p + '%', stfa, mtfa, htfa]
            
            else:
                return False
        else:
             return False
        