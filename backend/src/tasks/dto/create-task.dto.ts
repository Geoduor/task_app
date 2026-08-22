import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateTaskDto {
  @IsString({ message: 'title must be a string' })
  @IsNotEmpty({ message: 'title should not be empty' })
  @MinLength(1)
  @MaxLength(200, { message: 'title must not exceed 200 characters' })
  title!: string;
}
