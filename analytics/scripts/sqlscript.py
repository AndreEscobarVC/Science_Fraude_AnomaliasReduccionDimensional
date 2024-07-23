def run(action, model, dataset, search_text='query', server='kpi', verbose=False):

    import os
    import time 
    import numpy as np
    import pandas as pd
    import compress_pickle as cpickle

    import warnings
    # warnings.filterwarnings('ignore')

    from scripts import utils

    # ----------------------------------------------------
    # ------------------- AUX MODULES --------------------
    # ----------------------------------------------------

    def read_query(search, folder, v=False):
        
        if v: print('\nReading query ...')

        files = sorted([f for f in os.listdir(folder) if (search in f) & ('.sql' in f)])
        output = folder + files[-1]

        if v: print(f'   ... done! ({output})')

        return output
    
    def connect_sql(srv, v=False):

        if v: print('\nConnecting session ...')

        session = utils.CONNECT_SQL(server=srv, over='session')

        if v: print('   ... done!')

        return session
    
    # ----------------------------------------------------
    # ------------------- MAIN MODULES -------------------
    # ----------------------------------------------------

    def setup_folders(action, mod, dset, v=False):

        if v: print('\nSetting up folders ...')

        if action == 'input':
            
            # defino las carpetas
            infolder = f'models/{mod}/{dset}/queries/'
            outfolder = f'models/{mod}/{dset}/input/data/'

            # si la carpeta de output no existe, crearla
            if not os.path.exists(outfolder):
                os.makedirs(outfolder)

        else: 
            # defino las carpetas
            infolder = 'error'
            outfolder = 'error'

        if v: print(f'  ... done! ({infolder}, {outfolder})')

        return infolder, outfolder
        
    def load_sql_data(search, query_folder, data_folder, srv, v=False):

        # leo la query
        query = read_query(search=search, folder=query_folder, v=v)
        
        # me conecto a sql
        sess = connect_sql(srv=srv, v=v)

        # traigo los datos
        if v: print('\nExecuting query ...')

        stime = time.time()
        dataframe = utils.EXECUTE_SQL_QUERY(query, sess, over='session')
        elapsed = np.round((time.time() - stime) / 60, 2)

        if v: print(f'   ... done! ({elapsed} min)')

        return dataframe

    def save_sql_data(dataframe, local_folder, v=False):

        if v: print('\nSaving dataframe ...')

        stime = time.time()
        filename = local_folder + 'dataset' + utils.GET_NOW_STRING() + '.lzma'
        utils.SAVE_CPICKLE(dataframe, filename)
        elapsed = np.round((time.time() - stime) / 60, 2)

        if v: print(f'   ... done! ({elapsed} min)')

        return filename
    
    # ----------------------------------------------------
    # --------------- CALL MAIN MODULES ------------------
    # ----------------------------------------------------

    if action == 'input':

        # configuro el entorno
        infolder, outfolder = setup_folders(action=action, mod=model, dset=dataset, v=verbose)

        # cargo los datos
        dataframe = load_sql_data(search=search_text, query_folder=infolder, data_folder=outfolder, srv=server, v=verbose)

        # guardo los datos
        filename = save_sql_data(dataframe=dataframe, local_folder=outfolder, v=verbose)

    else:
        raise Exception('Invalid action: {}'.format(action))