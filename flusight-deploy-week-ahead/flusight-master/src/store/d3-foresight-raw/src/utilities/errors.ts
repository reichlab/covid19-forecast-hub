/**
 * Custom error for case when point type (the type of x axis) can't be handled
 */
export class UnknownPointType extends Error {}

/**
 * Custom error for situation when data provided for plotting is not quite right
 */
export class IncorrectData extends Error {}

/**
 * DOM related error
 */
export class DocumentError extends Error {}
