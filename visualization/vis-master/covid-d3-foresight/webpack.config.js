const path = require('path')

const PROD = JSON.parse(process.env.PROD_ENV || '0')

module.exports = {
  entry: path.resolve(__dirname, 'src/index.ts'),

  mode: PROD ? 'production' : 'development',

  output: {
    filename: PROD ? 'd3-foresight.min.js' : 'd3-foresight.js',
    path: path.resolve(__dirname, 'dist'),
    library: 'd3Foresight',
    libraryTarget: 'umd',
    umdNamedDefine: true
  },

  externals: {
    'd3': 'd3',
    'moment': 'moment'
  },

  resolve: {
    extensions: ['.ts', '.tsx', '.js']
  },

  module: {
    rules: [
      {
        test: /\.ts$/,
        loader: 'ts-loader'
      },
      {
        test: /\.js$/,
        loader: 'babel-loader',
        exclude: /node_modules/,
        options: {
          presets: ['env'],
          plugins: ['transform-object-rest-spread']
        }
      },
      {
        test: /\.scss$/,
        loaders: ['style-loader', 'css-loader', 'sass-loader?sourceMap']
      }
    ]
  }
}
